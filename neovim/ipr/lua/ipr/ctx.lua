local git = require 'ipr.git'
local base = require 'ipr.base'

local M = {}

---@class IprCtx : IprRepoInfo
---@field repo string
---@field base string
---@field base_source string
---@field merge_base string

local function repo_name(root)
  local url = git.git_value({ 'config', '--get', 'remote.origin.url' }, root)
  local name = url and url:match '([^/:]+)$'
  if name then
    return (name:gsub('%.git$', ''))
  end
  return vim.fs.basename(root)
end

---Repo facts that don't depend on the base.
---@param cwd? string
---@return IprRepoInfo?, string?
function M.repo_info(cwd)
  local root = git.root(cwd or vim.fn.getcwd())
  if not root then
    return nil, 'not in a git repository'
  end
  local head_sha = git.git_value({ 'rev-parse', 'HEAD' }, root)
  if not head_sha then
    return nil, 'repository has no commits'
  end
  return {
    root = root,
    head_sha = head_sha,
    branch = git.git_value({ 'branch', '--show-current' }, root),
    common_dir = git.git_value({ 'rev-parse', '--path-format=absolute', '--git-common-dir' }, root),
  }
end

---@param cwd? string
---@return IprCtx?, string?
function M.build(cwd)
  local info, err = M.repo_info(cwd)
  if not info then
    return nil, err
  end
  local resolved = base.resolve(info)
  if not resolved then
    return nil, 'could not determine a base branch; set one with :iPR base <ref>'
  end
  local merge_base = git.git_value({ 'merge-base', resolved.ref, 'HEAD' }, info.root)
  if not merge_base then
    return nil, 'no merge-base between ' .. resolved.ref .. ' and HEAD'
  end
  local ctx = info --[[@as IprCtx]]
  ctx.repo = repo_name(info.root)
  ctx.base = resolved.ref
  ctx.base_source = resolved.source
  ctx.merge_base = merge_base
  return ctx
end

---@param ctx IprCtx
function M.describe(ctx)
  return string.format('%s ← %s (via %s)', ctx.branch or ctx.head_sha:sub(1, 10), ctx.base, ctx.base_source)
end

return M
