M = {
  'jinh0/eyeliner.nvim',
  config = function()
    require('eyeliner').setup {
      -- show highlights only after key press (f/F/t/T)
      highlight_on_key = true,
    }
  end,
}

return M
