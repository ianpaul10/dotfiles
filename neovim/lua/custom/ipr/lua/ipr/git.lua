local M = {}

---@class IprRunResult
---@field ok boolean
---@field code integer
---@field stdout string
---@field stderr string

---Run a command synchronously. Never throws.
---@param cmd string[]
---@param opts? { cwd?: string }
---@return IprRunResult
function M.run(cmd, opts)
  opts = opts or {}
  local ok, res = pcall(function()
    return vim.system(cmd, { cwd = opts.cwd, text = true }):wait()
  end)
  if not ok then
    return { ok = false, code = -1, stdout = '', stderr = tostring(res) }
  end
  return { ok = res.code == 0, code = res.code, stdout = res.stdout or '', stderr = res.stderr or '' }
end

---@param args string[]
---@param cwd? string
---@return IprRunResult
function M.git(args, cwd)
  local cmd = { 'git', '-c', 'core.quotepath=off' }
  vim.list_extend(cmd, args)
  return M.run(cmd, { cwd = cwd })
end

---Trimmed stdout of a git command, or nil on failure / empty output.
---@param args string[]
---@param cwd? string
---@return string?
function M.git_value(args, cwd)
  local res = M.git(args, cwd)
  if not res.ok then
    return nil
  end
  local value = vim.trim(res.stdout)
  return value ~= '' and value or nil
end

---@param cwd? string
---@return string?
function M.root(cwd)
  return M.git_value({ 'rev-parse', '--show-toplevel' }, cwd)
end

---@class IprFileStatus
---@field status string single letter: A, M, D, R, C, T, ?
---@field path string
---@field old_path? string

---Parse `git diff --name-status -z` output.
---@param text string
---@return IprFileStatus[]
function M.parse_name_status(text)
  local fields = vim.split(text, '\0', { plain = true, trimempty = true })
  local files = {}
  local i = 1
  while i <= #fields do
    local status = fields[i]:sub(1, 1)
    if status == 'R' or status == 'C' then
      table.insert(files, { status = status, old_path = fields[i + 1], path = fields[i + 2] })
      i = i + 3
    else
      table.insert(files, { status = status, path = fields[i + 1] })
      i = i + 2
    end
  end
  return files
end

---@class IprHunk
---@field old_start integer
---@field old_count integer
---@field new_start integer
---@field new_count integer

local function strip_prefix(path)
  if path == '/dev/null' then
    return nil
  end
  return (path:gsub('^[ab]/', ''))
end

---Parse `git diff -U0` output into hunks keyed by the post-image path
---(pre-image path for deleted files).
---@param text string
---@return table<string, IprHunk[]>
function M.parse_hunks(text)
  local by_path = {}
  local old_path, current
  for line in vim.gsplit(text, '\n', { plain = true }) do
    if vim.startswith(line, 'diff --git ') then
      old_path, current = nil, nil
    elseif vim.startswith(line, '--- ') then
      old_path = strip_prefix(line:sub(5))
    elseif vim.startswith(line, '+++ ') then
      current = strip_prefix(line:sub(5)) or old_path
      if current then
        by_path[current] = by_path[current] or {}
      end
    elseif current and vim.startswith(line, '@@ ') then
      local os, oc, ns, nc = line:match '^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@'
      if os then
        table.insert(by_path[current], {
          old_start = tonumber(os),
          old_count = oc == '' and 1 or tonumber(oc),
          new_start = tonumber(ns),
          new_count = nc == '' and 1 or tonumber(nc),
        })
      end
    end
  end
  return by_path
end

---Line counts for a file's hunks. Within a hunk, paired old/new lines count as
---changed (~); the remainder is added (+) or removed (-).
---@param hunks IprHunk[]
---@return { added: integer, removed: integer, changed: integer }
function M.summarize(hunks)
  local added, removed, changed = 0, 0, 0
  for _, h in ipairs(hunks or {}) do
    local paired = math.min(h.old_count, h.new_count)
    changed = changed + paired
    added = added + h.new_count - paired
    removed = removed + h.old_count - paired
  end
  return { added = added, removed = removed, changed = changed }
end

---First line worth jumping to for a file's hunks.
---@param hunks IprHunk[]
---@param deleted boolean
---@return integer
function M.first_line(hunks, deleted)
  local h = hunks and hunks[1]
  if not h then
    return 1
  end
  local lnum = deleted and h.old_start or h.new_start
  return math.max(lnum, 1)
end

return M
