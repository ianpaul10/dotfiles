M = {
  'sindrets/diffview.nvim',
  config = function()
    require('diffview').setup()
    vim.keymap.set('n', '<leader>gf', '<cmd>DiffviewFileHistory %<CR>', { desc = '[G]it [f]ile history' })
    vim.keymap.set('n', '<leader>gc', '<cmd>DiffviewClose<CR>', { desc = '[G]it [c]lose diffview' })
  end,
}

return M
