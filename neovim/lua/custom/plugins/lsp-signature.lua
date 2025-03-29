vim.keymap.set({ 'n' }, '<C-k>', function()
  require('lsp_signature').toggle_float_win()
end, { silent = true, noremap = true, desc = 'toggle signature' })

return {
  {
    -- NOTE: this is the one with the panda
    'ray-x/lsp_signature.nvim',
    event = 'LspAttach',
    opts = {
      -- hint_prefix = '🐼 ',
      -- or, provide a table with 3 icons
      hint_prefix = {
        above = '↙ ', -- when the hint is on the line above the current line
        current = '← ', -- when the hint is on the same line
        below = '↖ ', -- when the hint is on the line below the current line
      },
    },
    config = function()
      require('lsp_signature').on_attach()
    end,
  },
}
