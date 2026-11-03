if vim.g.loaded_ipr then
  return
end
vim.g.loaded_ipr = true

-- User commands must start with an uppercase letter, so the real command is
-- :IPR and `iPR` is a command-line abbreviation for it.
vim.api.nvim_create_user_command('IPR', function(cmd)
  require('ipr').dispatch(cmd.fargs, cmd.bang)
end, {
  nargs = '*',
  bang = true,
  desc = 'iPR: local-first PR review',
  complete = function(arglead, cmdline)
    return require('ipr').complete(arglead, cmdline)
  end,
})

vim.cmd [[cnoreabbrev <expr> iPR (getcmdtype() ==# ':' && getcmdline() ==# 'iPR') ? 'IPR' : 'iPR']]
