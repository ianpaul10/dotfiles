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
