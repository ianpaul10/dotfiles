-- Point gitsigns at the PR's merge-base so the gutter shows every PR change.
local M = {}

---@type string? merge-base gitsigns is currently diffing against
M.base = nil

local function notify(msg, level)
  require('ipr').notify(msg, level)
end

local function gitsigns()
  local ok, gs = pcall(require, 'gitsigns')
  if not ok then
    notify('gitsigns.nvim is required for :iPR signs', vim.log.levels.ERROR)
    return nil
  end
  return gs
end

function M.is_on()
  return M.base ~= nil
end

---Turn PR signs on, or refresh them to the current merge-base (e.g. after a branch switch).
---@param ctx? IprCtx
function M.on(ctx)
  local gs = gitsigns()
  ctx = ctx or require('ipr.commands').ctx()
  if not (gs and ctx) then
    return
  end
  gs.change_base(ctx.merge_base, true)
  M.base = ctx.merge_base
  notify(string.format('signs: PR diff vs %s (%s). Stage/reset hunks act on this base; :iPR signs off first', ctx.base, ctx.merge_base:sub(1, 10)))
end

function M.off()
  local gs = gitsigns()
  if not gs then
    return
  end
  gs.reset_base(true)
  M.base = nil
  notify 'signs: back to index'
end

function M.toggle()
  if M.is_on() then
    M.off()
  else
    M.on()
  end
end

function M.status()
  if M.is_on() then
    notify('signs: on, diffing against ' .. M.base:sub(1, 10))
  else
    notify 'signs: off'
  end
end

---:iPR signs [on|off|toggle|status]
function M.command(args)
  local action = args[1] or 'toggle'
  local actions = { on = M.on, off = M.off, toggle = M.toggle, status = M.status }
  if not actions[action] then
    return notify('usage: :iPR signs [on|off|toggle|status]', vim.log.levels.ERROR)
  end
  actions[action]()
end

return M
