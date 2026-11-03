local git = require 'ipr.git'
local config = require 'ipr.config'

local M = {}

---@class IprRepoInfo
---@field root string
---@field branch? string nil when HEAD is detached
---@field head_sha string
---@field common_dir string

---@param info IprRepoInfo
---@param key string
local function branch_config(info, key)
  if not info.branch then
    return nil
  end
  return git.git_value({ 'config', '--get', 'branch.' .. info.branch .. '.' .. key }, info.root)
end

local function ref_exists(info, ref)
  return git.git({ 'rev-parse', '--verify', '--quiet', ref .. '^{commit}' }, info.root).ok
end

local function is_ancestor(info, a, b)
  return git.git({ 'merge-base', '--is-ancestor', a, b }, info.root).ok
end

---Remote-tracking name of the default branch, e.g. `origin/main`.
---@param info IprRepoInfo
---@return string?
function M.remote_default(info)
  return git.git_value({ 'symbolic-ref', '--quiet', '--short', 'refs/remotes/origin/HEAD' }, info.root)
end

---@type table<string, fun(info: IprRepoInfo): string?>
M.resolvers = {}

-- Explicit `:iPR base <ref>`, stored per branch in git config.
function M.resolvers.override(info)
  return branch_config(info, 'iprBase')
end

-- Opt-in network lookup of an existing PR's base branch.
function M.resolvers.forge(info)
  local forge = config.get().forge
  if forge == 'dt' then
    local res = git.run({ 'dt', 'pr', 'view', '--json' }, { cwd = info.root })
    local ok, data = pcall(vim.json.decode, res.ok and res.stdout or '')
    return ok and type(data) == 'table' and data.base and data.base.ref or nil
  elseif forge == 'gh' then
    local res = git.run({ 'gh', 'pr', 'view', '--json', 'baseRefName', '--jq', '.baseRefName' }, { cwd = info.root })
    local ref = res.ok and vim.trim(res.stdout) or ''
    return ref ~= '' and ref or nil
  end
end

-- Parent tracked by `dt create` / `dt track`. Local git config, works offline.
function M.resolvers.dt(info)
  return branch_config(info, 'wgh-parent')
end

-- Parent tracked by `gh stack`, stored as JSON in the common git dir.
function M.resolvers.gh_stack(info)
  if not info.branch then
    return nil
  end
  local f = io.open(info.common_dir .. '/gh-stack', 'r')
  if not f then
    return nil
  end
  local ok, data = pcall(vim.json.decode, f:read '*a')
  f:close()
  if not ok or type(data) ~= 'table' then
    return nil
  end
  for _, stack in ipairs(data.stacks or {}) do
    for i, entry in ipairs(stack.branches or {}) do
      if entry.branch == info.branch then
        if i > 1 then
          return stack.branches[i - 1].branch
        end
        return stack.trunk and stack.trunk.branch or nil
      end
    end
  end
end

local function short_ref(full)
  return full:gsub('^refs/heads/', ''):gsub('^refs/remotes/', '')
end

-- Nearest local branch (or the remote default branch) that HEAD is built on.
function M.resolvers.ancestor(info)
  local remote_default = M.remote_default(info)
  local args = {
    'log',
    '--topo-order',
    '--simplify-by-decoration',
    '--decorate=full',
    '--decorate-refs=refs/heads/',
    '--format=%H%x09%D',
    '-n',
    '200',
    'HEAD',
  }
  if remote_default then
    table.insert(args, 5, '--decorate-refs=refs/remotes/' .. remote_default)
  end
  local res = git.git(args, info.root)
  if not res.ok then
    return nil
  end
  for line in vim.gsplit(res.stdout, '\n', { plain = true, trimempty = true }) do
    local sha, decorations = line:match '^(%x+)\t(.*)$'
    if sha and sha ~= info.head_sha and decorations ~= '' then
      local candidates = {}
      for deco in vim.gsplit(decorations, ', ', { plain = true }) do
        local name = short_ref((deco:gsub('^HEAD %-> ', '')))
        if name ~= info.branch and name ~= 'HEAD' then
          table.insert(candidates, name)
        end
      end
      if #candidates > 0 then
        table.sort(candidates)
        local preferred = { remote_default, remote_default and (remote_default:gsub('^[^/]+/', '')) }
        for _, name in ipairs(preferred) do
          if vim.tbl_contains(candidates, name) then
            return name
          end
        end
        return candidates[1]
      end
    end
  end
end

function M.resolvers.default(info)
  local remote_default = M.remote_default(info)
  if remote_default then
    return remote_default
  end
  for _, name in ipairs { 'origin/main', 'origin/master', 'main', 'master' } do
    if ref_exists(info, name) then
      return name
    end
  end
end

M.order = { 'override', 'forge', 'dt', 'gh_stack', 'ancestor', 'default' }

---Prefer `origin/<ref>` when the local branch is stale relative to it, so a
---stale local `main` doesn't drag already-merged commits into the diff.
---@param info IprRepoInfo
---@param ref string
---@return string
function M.freshen(info, ref)
  if vim.startswith(ref, 'origin/') then
    return ref
  end
  local remote = 'origin/' .. ref
  if not ref_exists(info, remote) then
    return ref
  end
  if not ref_exists(info, ref) then
    return remote
  end
  local local_mb = git.git_value({ 'merge-base', ref, 'HEAD' }, info.root)
  local remote_mb = git.git_value({ 'merge-base', remote, 'HEAD' }, info.root)
  if local_mb and remote_mb and local_mb ~= remote_mb and is_ancestor(info, local_mb, remote_mb) then
    return remote
  end
  return ref
end

---@param info IprRepoInfo
---@return { ref: string, source: string }?
function M.resolve(info)
  for _, name in ipairs(M.order) do
    local ref = M.resolvers[name](info)
    if ref and ref ~= info.branch and ref_exists(info, ref) then
      return { ref = M.freshen(info, ref), source = name }
    elseif ref and ref ~= info.branch and ref_exists(info, 'origin/' .. ref) then
      return { ref = 'origin/' .. ref, source = name }
    end
  end
end

---@param info IprRepoInfo
---@param ref string
---@return boolean ok, string? err
function M.set_override(info, ref)
  if not info.branch then
    return false, 'HEAD is detached; check out a branch to save a base override'
  end
  if not ref_exists(info, ref) then
    return false, 'not a valid ref: ' .. ref
  end
  local res = git.git({ 'config', 'branch.' .. info.branch .. '.iprBase', ref }, info.root)
  return res.ok, res.ok and nil or res.stderr
end

---@param info IprRepoInfo
function M.clear_override(info)
  if info.branch then
    git.git({ 'config', '--unset', 'branch.' .. info.branch .. '.iprBase' }, info.root)
  end
end

return M
