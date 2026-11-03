local config = require 'ipr.config'

local M = {}

---@class IprSubcommand
---@field run fun(args: string[], bang: boolean)
---@field desc string
---@field args? string[] completion candidates for the first argument

---@type table<string, IprSubcommand>
M.subcommands = {
  base = {
    desc = 'Show the resolved base; `base <ref>` saves an override, `base --clear` removes it',
    run = function(args)
      require('ipr.commands').base(args)
    end,
  },
  files = {
    desc = 'Changed files in quickfix; `files!` includes uncommitted changes',
    run = function(_, bang)
      require('ipr.quickfix').open(bang)
    end,
  },
  walkthrough = {
    desc = 'Write a review walkthrough with headless pi',
    run = function()
      local ctx = require('ipr.commands').ctx()
      if ctx then
        require('ipr.walkthrough').start(ctx)
      end
    end,
  },
  cancel = {
    desc = 'Cancel the running walkthrough',
    run = function()
      require('ipr.walkthrough').cancel()
    end,
  },
  open = {
    desc = 'Open the latest review for this branch in a right split; `open <path>` opens a specific one',
    run = function(args)
      require('ipr.viewer').open_command(args)
    end,
  },
  links = {
    desc = 'All links in the review into quickfix',
    run = function()
      require('ipr.links').to_quickfix()
    end,
  },
  signs = {
    desc = 'Gutter signs vs the PR base: `signs [on|off|toggle|status]` (default toggle)',
    args = { 'on', 'off', 'toggle', 'status' },
    run = function(args)
      require('ipr.signs').command(args)
    end,
  },
}

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

local function starting_with(list, prefix)
  return vim.tbl_filter(function(name)
    return vim.startswith(name, prefix)
  end, list)
end

function M.complete(arglead, cmdline)
  local words = vim.split(cmdline, '%s+', { trimempty = true })
  local completing_sub = #words < 2 or (#words == 2 and arglead ~= '')
  if completing_sub then
    return starting_with(M.subcommand_names(), arglead)
  end
  local sub = M.subcommands[words[2]]
  local completing_first_arg = #words == 2 or (#words == 3 and arglead ~= '')
  if sub and sub.args and completing_first_arg then
    return starting_with(sub.args, arglead)
  end
  return {}
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
  map(keys.signs, '<cmd>IPR signs toggle<CR>', 'toggle PR gutter [s]igns')
end

local function attach_reviews()
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
    group = vim.api.nvim_create_augroup('ipr_reviews', { clear = true }),
    pattern = config.reviews_dir() .. '/*.md',
    callback = function(ev)
      require('ipr.links').attach(ev.buf)
    end,
  })
end

function M.setup(opts)
  local options = config.setup(opts)
  set_keymaps(options.keys)
  attach_reviews()
end

return M
