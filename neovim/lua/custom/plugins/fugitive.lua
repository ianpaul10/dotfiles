local function browse_file_on_github()
  if vim.fn.FugitiveHead() == '.invalid' then
    vim.cmd 'GBrowse main:%'
  else
    vim.cmd.GBrowse()
  end
end

return {
  'tpope/vim-fugitive',
  dependencies = { 'tpope/vim-rhubarb' },
  keys = {
    {
      '<leader>gs',
      ':10split|0Git<CR>',
      desc = '[G]it [s]tatus',
    },
    {
      '<leader>go',
      browse_file_on_github,
      desc = '[G]it [o]pen file in GitHub',
    },
    {
      '<leader>gO',
      'V:GBrowse<CR>',
      desc = '[G]it [o]pen file in GitHub',
    },

  },
}
