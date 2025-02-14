local M = {
  'vim-test/vim-test',
}

vim.keymap.set('n', '<leader>tt', ':TestNearest<CR>', { desc = '[T]est nearest' })
vim.keymap.set('n', '<leader>tf', ':TestFile<CR>', { desc = '[T]est [f]ile' })
vim.keymap.set('n', '<leader>ta', ':TestSuite<CR>', { desc = '[T]est [a]ll' })
vim.keymap.set('n', '<leader>tl', ':TestLast<CR>', { desc = 'Re-run [l]ast test' })

return M
