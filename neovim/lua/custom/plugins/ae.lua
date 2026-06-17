local function value_or_nil(value)
  if value == nil or value == vim.NIL or value == '' then
    return nil
  end

  return tostring(value):gsub('%s+', ' ')
end

local function append_field(parts, label, value)
  value = value_or_nil(value)

  if value then
    table.insert(parts, label .. ': ' .. value)
  end
end

local function review_summary_text(summary)
  if type(summary) ~= 'table' then
    return nil
  end

  local approved = tonumber(summary.approved) or 0
  local changes_requested = tonumber(summary.changes_requested) or 0
  local commented = tonumber(summary.commented) or 0

  if approved == 0 and changes_requested == 0 and commented == 0 then
    return nil
  end

  return string.format('reviews: +%d ~%d -%d', approved, commented, changes_requested)
end

local function ae_root_dir()
  return value_or_nil(vim.env.AE_ROOT_DIR) or vim.fn.expand '~/.ae'
end

local function latest_pi_session_id(task_id)
  task_id = value_or_nil(task_id)
  if not task_id then
    return nil
  end

  local session_files = vim.fn.glob(ae_root_dir() .. '/sessions/task-' .. task_id .. '/*.jsonl', false, true)
  if #session_files == 0 then
    return nil
  end

  table.sort(session_files)

  local filename = vim.fn.fnamemodify(session_files[#session_files], ':t')
  return filename:match '_([0-9a-fA-F%-]+)%.jsonl$'
end

local function first_existing_dir(paths)
  for _, path in ipairs(paths) do
    local expanded_paths = vim.fn.glob(vim.fn.expand(path), false, true)
    if #expanded_paths == 0 then
      expanded_paths = { vim.fn.expand(path) }
    end

    table.sort(expanded_paths)

    for _, expanded in ipairs(expanded_paths) do
      if vim.fn.isdirectory(expanded) == 1 then
        return vim.fs.normalize(expanded)
      end
    end
  end

  return nil
end

local function worktree_path(task)
  local worktree = value_or_nil(task.worktree)
  if not worktree then
    return nil
  end

  local candidates = { worktree }
  local scope = value_or_nil(task.scope)

  if scope and scope:sub(1, 2) == '//' then
    table.insert(candidates, '~/world/trees/' .. worktree)
  end

  local org, repo = scope and scope:match '^github%.com/([^/]+)/([^/]+)$'
  if org and repo then
    table.insert(candidates, ae_root_dir() .. '/worktrees/' .. org .. '/' .. repo .. '/' .. worktree)
  end

  table.insert(candidates, '~/world/trees/' .. worktree)
  table.insert(candidates, ae_root_dir() .. '/worktrees/*/*/' .. worktree)

  return first_existing_dir(candidates)
end

local function root_open_tasks(tasks)
  local filtered = {}

  for _, task in ipairs(tasks) do
    if value_or_nil(task.state) ~= 'done' and value_or_nil(task.parent_task_id) == nil then
      table.insert(filtered, task)
    end
  end

  return filtered
end

local function render_tasks(tasks)
  tasks = root_open_tasks(tasks)

  local lines = {
    'AE Tasks',
    '========',
    '',
  }

  if #tasks == 0 then
    table.insert(lines, 'No non-done root tasks found')
  end

  local sections = {}

  for _, task in ipairs(tasks) do
    local title = value_or_nil(task.title) or '<untitled>'
    local state = value_or_nil(task.state) or 'unknown'
    local id = value_or_nil(task.id) or '?'
    local section_start = #lines + 1

    table.insert(lines, string.format('%s [%s] %s', id, state, title))

    local details = {}
    append_field(details, 'scope', task.scope)
    local kind = value_or_nil(task.kind)
    local review_type = value_or_nil(task.review_type)
    append_field(details, 'kind', kind and review_type and (kind .. '/' .. review_type) or kind)
    append_field(details, 'base', task.base_branch)

    if #details > 0 then
      table.insert(lines, '  ' .. table.concat(details, ' | '))
    end

    local workflow = {}
    append_field(workflow, 'pi session', latest_pi_session_id(task.id))
    append_field(workflow, 'worktree', task.worktree)
    append_field(workflow, 'branch', task.branch_name)
    append_field(workflow, 'ci', task.ci_state)
    append_field(workflow, 'merge', task.merge_state)

    local summary = review_summary_text(task.review_summary)
    if summary then
      table.insert(workflow, summary)
    end

    if #workflow > 0 then
      table.insert(lines, '  ' .. table.concat(workflow, ' | '))
    end

    append_field(lines, '  pr', task.pull_request_url)
    append_field(lines, '  needs input', task.needs_input_reason)
    append_field(lines, '  locked by', task.locked_by)
    append_field(lines, '  last error', task.last_error)

    if task.paused then
      table.insert(lines, '  paused: true')
    end

    table.insert(lines, '')

    table.insert(sections, {
      start_line = section_start,
      end_line = #lines,
      task_id = id,
      worktree = value_or_nil(task.worktree),
      worktree_path = worktree_path(task),
    })
  end

  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_name(buf, 'ae://tasks/' .. vim.uv.hrtime())
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_set_option_value('filetype', 'ae-tasks', { buf = buf })

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.b[buf].ae_task_sections = sections
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  vim.api.nvim_win_set_buf(0, buf)
end

local function current_task_section()
  local sections = vim.b.ae_task_sections
  if type(sections) ~= 'table' then
    return nil
  end

  local line = vim.fn.line '.'
  for _, section in ipairs(sections) do
    if line >= section.start_line and line <= section.end_line then
      return section
    end
  end

  return nil
end

local function ae_cd_worktree()
  local section = current_task_section()
  if not section then
    vim.notify('Cursor is not on an AE task section', vim.log.levels.WARN)
    return
  end

  if not section.worktree_path then
    vim.notify('No worktree path found for task ' .. section.task_id, vim.log.levels.WARN)
    return
  end

  vim.cmd('cd ' .. vim.fn.fnameescape(section.worktree_path))
  vim.notify('Changed directory to ' .. section.worktree_path, vim.log.levels.INFO)
end

local function ae_task_list(opts)
  local cmd = { 'ae', 'task', 'list', '--json' }
  local state = opts and opts.args and opts.args ~= '' and opts.args or nil

  if state then
    table.insert(cmd, '--state')
    table.insert(cmd, state)
  end

  vim.notify('Loading AE tasks...', vim.log.levels.INFO)

  vim.system(cmd, { text = true }, function(result)
    if result.code ~= 0 then
      vim.schedule(function()
        vim.notify('ae task list failed:\n' .. (result.stderr or ''), vim.log.levels.ERROR)
      end)
      return
    end

    local ok, tasks = pcall(vim.json.decode, result.stdout)
    if not ok or type(tasks) ~= 'table' then
      vim.schedule(function()
        vim.notify('Failed to parse ae task list JSON', vim.log.levels.ERROR)
      end)
      return
    end

    vim.schedule(function()
      render_tasks(tasks)
    end)
  end)
end

vim.api.nvim_create_user_command('AE', ae_task_list, {
  nargs = '?',
  complete = function()
    return { 'backlog', 'ready', 'in_progress', 'automatic_review', 'review', 'done' }
  end,
  desc = 'List AE tasks in a scratch buffer',
})

vim.api.nvim_create_user_command('AECdWorktree', ae_cd_worktree, {
  desc = 'Change cwd to the AE task worktree under the cursor',
})

return {}
