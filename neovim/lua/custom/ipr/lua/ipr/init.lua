local config = require 'ipr.config'

local M = {}

---@class IprSubcommand
---@field run fun(args: string[], bang: boolean)
---@field desc string

---@type table<string, IprSubcommand>
M.subcommands = {}

local function notify(msg, level)
  vim.notify('iPR: ' .. msg, level or vim.log.levels.INFO)
end
M.notify = notify

function M.subcommand_names()
  local names = vim.tbl_keys(M.subcommands)
  table.sort(names)
  return names
end

function M.dispatch(fargs, bang)
  local name = fargs[1]
  if not name then
    notify('subcommands: ' .. table.concat(M.subcommand_names(), ', '))
    return
  end
  local sub = M.subcommands[name]
  if not sub then
    notify('unknown subcommand: ' .. name, vim.log.levels.ERROR)
    return
  end
  sub.run(vim.list_slice(fargs, 2), bang)
end

function M.complete(arglead, cmdline)
  local words = vim.split(cmdline, '%s+', { trimempty = true })
  local completing_sub = #words < 2 or (#words == 2 and arglead ~= '')
  if not completing_sub then
    return {}
  end
  return vim.tbl_filter(function(name)
    return vim.startswith(name, arglead)
  end, M.subcommand_names())
end

local function map(lhs, rhs, desc)
  if lhs then
    vim.keymap.set('n', lhs, rhs, { desc = 'iPR: ' .. desc })
  end
end

local function set_keymaps(keys)
  map(keys.files, '<cmd>IPR files<CR>', 'changed [f]iles')
  map(keys.files_all, '<cmd>IPR files!<CR>', 'changed [F]iles incl. uncommitted')
  map(keys.walkthrough, '<cmd>IPR walkthrough<CR>', '[w]alkthrough with pi')
  map(keys.open, '<cmd>IPR open<CR>', '[o]pen review')
  map(keys.base, '<cmd>IPR base<CR>', 'show [b]ase')
  map(keys.links, '<cmd>IPR links<CR>', 'review [l]inks to quickfix')
end

function M.setup(opts)
  local options = config.setup(opts)
  set_keymaps(options.keys)
end

return M
