M = {
  'Xuyuanp/nes.nvim',
  event = 'VeryLazy',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  opts = {},
}

vim.keymap.set('i', '<C-i>', function()
  -- add logging
  vim.print 'nes'
  require('nes').get_suggestion()
end, { desc = '[Nes] get suggestion' })
vim.keymap.set('i', '<C-a>', function()
  require('nes').apply_suggestion(0, { jump = true, trigger = true })
end, { desc = '[Nes] apply suggestion' })
vim.keymap.set('i', '<C-e>', function()
  require('nes').clear_suggestion(0)
end, { desc = '[Nes] clear suggestion' })

return M
