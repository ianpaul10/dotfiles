local M = {}

local function notify(msg, level)
  require('ipr').notify(msg, level)
end

---Build ctx or report why we can't.
---@return IprCtx?
function M.ctx()
  local ctx, err = require('ipr.ctx').build()
  if not ctx then
    notify(err, vim.log.levels.ERROR)
  end
  return ctx
end

function M.base(args)
  local ctx_mod = require 'ipr.ctx'
  local base = require 'ipr.base'
  local ref = args[1]
  if ref then
    local info, err = ctx_mod.repo_info()
    if not info then
      return notify(err, vim.log.levels.ERROR)
    end
    if ref == '--clear' then
      base.clear_override(info)
      notify 'base override cleared'
    else
      local ok, set_err = base.set_override(info, ref)
      if not ok then
        return notify(set_err, vim.log.levels.ERROR)
      end
    end
  end
  local ctx = M.ctx()
  if ctx then
    local count = require('ipr.git').git_value({ 'rev-list', '--count', ctx.merge_base .. '..HEAD' }, ctx.root) or '?'
    notify(string.format('%s · merge-base %s · %s commits', ctx_mod.describe(ctx), ctx.merge_base:sub(1, 10), count))
  end
end

return M
