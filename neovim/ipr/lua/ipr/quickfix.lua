local git = require 'ipr.git'

local M = {}

---@class IprChangedFile : IprFileStatus
---@field hunks IprHunk[]
---@field added? integer
---@field removed? integer
---@field changed? integer

---Changed files between two revisions.
---@param root string
---@param from string
---@param to? string nil diffs the working tree (staged + unstaged) and adds untracked files
---@return IprChangedFile[]?, string?
function M.collect_range(root, from, to)
  local range = { from, to }

  local ns_args = { 'diff', '--no-ext-diff', '--name-status', '-z', '-M' }
  local ns = git.git(vim.list_extend(ns_args, range), root)
  if not ns.ok then
    return nil, ns.stderr
  end
  local hunk_args = { 'diff', '--no-ext-diff', '--no-color', '-U0', '-M', '--src-prefix=a/', '--dst-prefix=b/' }
  local diff = git.git(vim.list_extend(hunk_args, range), root)
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

  if not to then
    local untracked = git.git({ 'ls-files', '--others', '--exclude-standard', '-z' }, root)
    for _, path in ipairs(vim.split(untracked.stdout, '\0', { plain = true, trimempty = true })) do
      table.insert(files, { status = '?', path = path, hunks = {} })
    end
  end

  table.sort(files, function(a, b)
    return a.path < b.path
  end)
  return files
end

---PR files: merge-base..HEAD, or merge-base..working tree with include_worktree.
---@param ctx IprCtx
---@param include_worktree boolean
---@return IprChangedFile[]?, string?
function M.collect(ctx, include_worktree)
  return M.collect_range(ctx.root, ctx.merge_base, not include_worktree and 'HEAD' or nil)
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

---Filename to open for a quickfix entry. Deleted files open read-only from
---`deleted_rev` (default: the PR merge-base).
---@param ctx { root: string, merge_base?: string }
---@param file IprChangedFile
---@param deleted_rev? string
---@return string
function M.filename(ctx, file, deleted_rev)
  if file.status == 'D' then
    return require('ipr.gitbuf').uri(ctx.root, deleted_rev or ctx.merge_base, file.path)
  end
  return ctx.root .. '/' .. file.path
end

---@param ctx { root: string, merge_base?: string }
---@param files IprChangedFile[]
---@param deleted_rev? string
function M.items(ctx, files, deleted_rev)
  local items = {}
  for _, file in ipairs(files) do
    local display = M.format(file)
    table.insert(items, {
      filename = M.filename(ctx, file, deleted_rev),
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

---@param files IprChangedFile[]
local function totals(files)
  local added, removed, changed = 0, 0, 0
  for _, f in ipairs(files) do
    added = added + (f.added or 0)
    removed = removed + (f.removed or 0)
    changed = changed + (f.changed or 0)
  end
  return string.format('%d files +%d -%d ~%d', #files, added, removed, changed)
end

---@param ctx IprCtx
---@param files IprChangedFile[]
function M.title(ctx, files, include_worktree)
  if #files == 0 then
    return 'iPR: no changes vs ' .. ctx.base
  end
  return string.format(
    'iPR: %s%s · %s',
    require('ipr.ctx').describe(ctx),
    include_worktree and ' +worktree' or '',
    totals(files)
  )
end

---@param info IprRepoInfo
---@param files IprChangedFile[]
function M.uncommitted_title(info, files)
  local where = info.branch or info.head_sha:sub(1, 10)
  if #files == 0 then
    return 'iPR: no uncommitted changes on ' .. where
  end
  return string.format('iPR: uncommitted on %s · %s', where, totals(files))
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
  M.show(M.title(ctx, files, include_worktree), M.items(ctx, files))
  if require('ipr.config').get().signs_on_files then
    require('ipr.signs').on(ctx)
  end
end

---Staged, unstaged and untracked changes vs HEAD. Doesn't need a PR base.
function M.open_uncommitted()
  local info, err = require('ipr.ctx').repo_info()
  if not info then
    return require('ipr').notify(err, vim.log.levels.ERROR)
  end
  local files, diff_err = M.collect_range(info.root, 'HEAD', nil)
  if not files then
    return require('ipr').notify(diff_err, vim.log.levels.ERROR)
  end
  M.show(M.uncommitted_title(info, files), M.items(info, files, info.head_sha))
end

function M.show(title, items)
  vim.fn.setqflist({}, ' ', { title = title, items = items, quickfixtextfunc = M.textfunc })
  vim.cmd 'botright copen'
end

return M
