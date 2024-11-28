return {
  'tpope/vim-fugitive',
  dependencies = { 'tpope/vim-rhubarb' },
  keys = {
    {
      '<leader>gs',
      vim.cmd.Git,
      desc = '[G]it [s]tatus',
    },
    {
      '<leader>go',
      ':GBrowse<CR>',
      desc = '[G]it [o]pen file in GitHub',
    },
  },
}
