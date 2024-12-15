return {
  'stevanmilic/nvim-lspimport',
  config = function()
    vim.keymap.set('n', '<leader>ci', require('lspimport').import, { desc = '[C]ode Auto [I]mport' })
  end,
}
