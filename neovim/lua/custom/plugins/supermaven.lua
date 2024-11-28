-- [[ SuperMaven ]]
-- source: https://github.com/supermaven/supermaven-nvim
-- Basic SuperMaven setup
-- Docs: https://github.com/supermaven/supermaven-nvim

vim.keymap.set('n', '<leader>sm', ':SupermavenToggle<CR>', { desc = 'Toggle [S]uper[M]aven' })

return {
  'supermaven-inc/supermaven-nvim',
  config = function()
    require('supermaven-nvim').setup {
      keymaps = {
        accept_suggestion = '<C-=>',
        clear_suggestion = '<C-]>',
        accept_word = '<C-j>',
      },
    }
  end,
}
