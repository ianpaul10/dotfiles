local git = require 'ipr.git'

local M = {}

---@class IprChangedFile : IprFileStatus
---@field hunks IprHunk[]
---@field added? integer
---@field removed? integer
---@field changed? integer

---@param ctx IprCtx
---@param include_worktree boolean diff the working tree (staged + unstaged + untracked) instead of HEAD
---@return IprChangedFile[]?, string?
function M.collect(ctx, include_worktree)
  local range = include_worktree and { ctx.merge_base } or { ctx.merge_base, 'HEAD' }

  local ns_args = { 'diff', '--no-ext-diff', '--name-status', '-z', '-M' }
  local ns = git.git(vim.list_extend(ns_args, range), ctx.root)
  if not ns.ok then
    return nil, ns.stderr
  end
  local hunk_args = { 'diff', '--no-ext-diff', '--no-color', '-U0', '-M', '--src-prefix=a/', '--dst-prefix=b/' }
  local diff = git.git(vim.list_extend(hunk_args, range), ctx.root)
  if not diff.ok then
    return nil, diff.stderr
  end

  local hunks = git.parse_hunks(diff.stdout)
  local files = git.parse_name_status(ns.stdout)
  for _, file in ipairs(files) do
    file.hunks = hunks[file.path] or {}
    local stats = git.summarize(file.hunks)
    file.added, file.removed, file.changed = stats.added, stats.removed, stats.changed
  end

  if include_worktree then
    local untracked = git.git({ 'ls-files', '--others', '--exclude-standard', '-z' }, ctx.root)
    for _, path in ipairs(vim.split(untracked.stdout, '\0', { plain = true, trimempty = true })) do
      table.insert(files, { status = '?', path = path, hunks = {} })
    end
  end

  table.sort(files, function(a, b)
    return a.path < b.path
  end)
  return files
end

local function count(prefix, n)
  return (n and n > 0) and (prefix .. n) or ''
end

---@param file IprChangedFile
---@return string
function M.format(file)
  local path = file.old_path and (file.old_path .. ' → ' .. file.path) or file.path
  return string.format(
    '%-2s %6s %6s %6s  %s',
    file.status,
    count('+', file.added),
    count('-', file.removed),
    count('~', file.changed),
    path
  )
end

---Filename to open for a quickfix entry.
---@param ctx IprCtx
---@param file IprChangedFile
---@return string
function M.filename(ctx, file)
  return ctx.root .. '/' .. file.path
end

---@param ctx IprCtx
---@param files IprChangedFile[]
function M.items(ctx, files)
  local items = {}
  for _, file in ipairs(files) do
    local display = M.format(file)
    table.insert(items, {
      filename = M.filename(ctx, file),
      lnum = git.first_line(file.hunks, file.status == 'D'),
      text = display,
      user_data = {
        display = display,
        status = file.status,
        path = file.path,
        old_path = file.old_path,
        added = file.added,
        removed = file.removed,
        changed = file.changed,
        hunks = file.hunks,
      },
    })
  end
  return items
end

---@param ctx IprCtx
---@param files IprChangedFile[]
function M.title(ctx, files, include_worktree)
  if #files == 0 then
    return 'iPR: no changes vs ' .. ctx.base
  end
  local added, removed, changed = 0, 0, 0
  for _, f in ipairs(files) do
    added = added + (f.added or 0)
    removed = removed + (f.removed or 0)
    changed = changed + (f.changed or 0)
  end
  return string.format(
    'iPR: %s%s · %d files +%d -%d ~%d',
    require('ipr.ctx').describe(ctx),
    include_worktree and ' +worktree' or '',
    #files,
    added,
    removed,
    changed
  )
end

---quickfixtextfunc: render the aligned summary instead of `path|lnum| text`.
function M.textfunc(info)
  local what = { id = info.id, items = 1 }
  local list = info.quickfix == 1 and vim.fn.getqflist(what) or vim.fn.getloclist(info.winid, what)
  local lines = {}
  for i = info.start_idx, info.end_idx do
    local item = list.items[i]
    local ud = item.user_data
    lines[#lines + 1] = type(ud) == 'table' and ud.display or item.text
  end
  return lines
end

---@param include_worktree boolean
function M.open(include_worktree)
  local ctx = require('ipr.commands').ctx()
  if not ctx then
    return
  end
  local files, err = M.collect(ctx, include_worktree)
  if not files then
    return require('ipr').notify(err, vim.log.levels.ERROR)
  end
  vim.fn.setqflist({}, ' ', {
    title = M.title(ctx, files, include_worktree),
    items = M.items(ctx, files),
    quickfixtextfunc = M.textfunc,
  })
  vim.cmd 'botright copen'
end

return M
