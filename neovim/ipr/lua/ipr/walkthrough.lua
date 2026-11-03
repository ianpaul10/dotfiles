local config = require 'ipr.config'
local git = require 'ipr.git'
local frontmatter = require 'ipr.frontmatter'

local M = {}

---@class IprJob
---@field proc vim.SystemObj
---@field output_path string
---@field log_path string
---@field ctx IprCtx

---@type IprJob?
M.job = nil

---@type { ok: boolean, output_path: string, err?: string }?
M.last = nil

local function notify(msg, level)
  require('ipr').notify(msg, level)
end

-- Overridable for tests.
function M.confirm(msg)
  return vim.fn.confirm(msg, '&Yes\n&No', 2) == 1
end

function M.plugin_root()
  local source = debug.getinfo(1, 'S').source:sub(2)
  return vim.fn.fnamemodify(source, ':p:h:h:h')
end

---@return string skill_arg path passed to `pi --skill`, skill_file SKILL.md to read
function M.skill_paths()
  local skill = config.get().skill
  local path = skill and vim.fs.normalize(vim.fn.expand(skill)) or (M.plugin_root() .. '/skills/ipr-walkthrough')
  if vim.fn.isdirectory(path) == 1 then
    return path, path .. '/SKILL.md'
  end
  return path, path
end

function M.slug(s)
  return (s:gsub('[^%w%._-]+', '-'))
end

---@param ctx IprCtx
---@param date? string YYYY_MM_DD
function M.output_path(ctx, date)
  local name = string.format(
    '%s_%s_%s_%s.md',
    date or os.date '%Y_%m_%d',
    M.slug(ctx.repo),
    M.slug(ctx.branch or 'detached'),
    ctx.head_sha:sub(1, 10)
  )
  return config.reviews_dir() .. '/' .. name
end

local function capped(text, max_lines)
  local lines = vim.split(vim.trim(text), '\n', { plain = true })
  if #lines > max_lines then
    local dropped = #lines - max_lines
    lines = vim.list_slice(lines, 1, max_lines)
    table.insert(lines, string.format('... (%d more lines)', dropped))
  end
  return table.concat(lines, '\n')
end

---@param ctx IprCtx
---@param opts { output_path: string, skill_file: string }
function M.build_prompt(ctx, opts)
  local range = ctx.merge_base .. '..HEAD'
  local log = git.git({ 'log', '--oneline', '--no-decorate', range }, ctx.root).stdout
  local stat = git.git({ 'diff', '--stat=200', range }, ctx.root).stdout
  local branch = ctx.branch or '(detached)'

  return table.concat({
    'Write a PR review walkthrough for the current branch.',
    '',
    'Read and follow the skill at ' .. opts.skill_file .. ' before starting.',
    '',
    'Repository root: ' .. ctx.root,
    'Branch: ' .. branch,
    string.format('Base: %s (resolved via %s)', ctx.base, ctx.base_source),
    'Merge base: ' .. ctx.merge_base,
    'HEAD: ' .. ctx.head_sha,
    'Diff range: ' .. range .. ' (use `git diff ' .. range .. '`)',
    '',
    'Commits:',
    capped(log, 100),
    '',
    'Diffstat:',
    capped(stat, 300),
    '',
    'Output requirements (these override the skill if they conflict):',
    '1. Write the guide to exactly this file using your write tool: ' .. opts.output_path,
    '2. Do not create, modify, or delete any other file. Do not commit, push, or switch branches.',
    '3. Start the file with this YAML frontmatter, verbatim:',
    '---',
    'repo_root: ' .. ctx.root,
    'branch: ' .. branch,
    'base: ' .. ctx.base,
    'merge_base: ' .. ctx.merge_base,
    'head_sha: ' .. ctx.head_sha,
    '---',
    '4. Reference code as `path:LINE` or `path:START-END` in backticks, with paths relative to the repository root.',
    '5. When finished, reply with only the output path.',
  }, '\n')
end

---@param path string
---@return boolean ok, string? err
function M.validate(path)
  if vim.fn.filereadable(path) == 0 then
    return false, 'pi finished but did not write ' .. path
  end
  if not frontmatter.read_file(path).head_sha then
    return false, 'review is missing head_sha frontmatter: ' .. path
  end
  return true
end

local function write_log(path, result)
  local f = io.open(path, 'w')
  if f then
    f:write(string.format('exit code: %d\n\n--- stdout ---\n%s\n--- stderr ---\n%s\n', result.code, result.stdout or '', result.stderr or ''))
    f:close()
  end
end

---@param job IprJob
---@param result vim.SystemCompleted
local function on_exit(job, result)
  local output_path, log_path = job.output_path, job.log_path
  write_log(log_path, result)
  if M.job ~= job then
    return -- cancelled
  end
  M.job = nil
  local ok, err
  if result.code ~= 0 then
    ok, err = false, string.format('pi exited with code %d', result.code)
  else
    ok, err = M.validate(output_path)
  end
  M.last = { ok = ok, output_path = output_path, err = err }
  if not ok then
    return notify(string.format('walkthrough failed: %s (log: %s)', err, log_path), vim.log.levels.ERROR)
  end
  vim.fn.delete(log_path)
  notify('walkthrough ready: ' .. vim.fn.fnamemodify(output_path, ':~') .. ' (:iPR open)')
  if config.get().open_on_complete then
    require('ipr.viewer').open(output_path, job.ctx)
  end
end

---@param ctx IprCtx
function M.start(ctx)
  if M.job then
    if not M.confirm 'iPR: a walkthrough is already running. Cancel it and start a new one?' then
      return
    end
    M.cancel()
  end

  local output_path = M.output_path(ctx)
  if vim.fn.filereadable(output_path) == 1 then
    if not M.confirm('iPR: overwrite ' .. vim.fn.fnamemodify(output_path, ':~') .. '?') then
      return
    end
    vim.fn.delete(output_path)
  end
  vim.fn.mkdir(vim.fs.dirname(output_path), 'p')

  local cfg = config.get()
  local skill_arg, skill_file = M.skill_paths()
  local cmd = { cfg.pi_cmd }
  vim.list_extend(cmd, cfg.pi_args)
  vim.list_extend(cmd, { '--skill', skill_arg, M.build_prompt(ctx, { output_path = output_path, skill_file = skill_file }) })

  local job = { output_path = output_path, log_path = (output_path:gsub('%.md$', '.log')), ctx = ctx }
  local ok, proc = pcall(vim.system, cmd, { cwd = ctx.root, text = true }, vim.schedule_wrap(function(result)
    on_exit(job, result)
  end))
  if not ok then
    return notify('could not start ' .. cfg.pi_cmd .. ': ' .. tostring(proc), vim.log.levels.ERROR)
  end
  job.proc = proc
  M.job = job
  notify('walkthrough started → ' .. vim.fn.fnamemodify(output_path, ':~'))
  return M.job
end

function M.cancel()
  if not M.job then
    return notify 'no walkthrough running'
  end
  M.job.proc:kill(15)
  M.job = nil
  notify 'walkthrough cancelled'
end

return M
