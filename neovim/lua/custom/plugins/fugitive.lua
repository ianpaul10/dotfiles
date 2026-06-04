local function git_status()
  vim.cmd.Git()
  vim.cmd.resize(10)
end

return {
  'tpope/vim-fugitive',
  dependencies = { 'tpope/vim-rhubarb' },
  keys = {
    {
      '<leader>gs',
      git_status,
      desc = '[G]it [s]tatus',
    },
    {
      '<leader>go',
      ':GBrowse<CR>',
      desc = '[G]it [o]pen file in GitHub',
    },
    {
      '<leader>gO',
      'V:GBrowse<CR>',
      desc = '[G]it [o]pen file in GitHub',
    },

  },
}
