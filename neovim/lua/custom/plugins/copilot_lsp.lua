return {
  'copilotlsp-nvim/copilot-lsp',
  init = function()
    vim.g.copilot_nes_debounce = 500
    -- The vim.lsp.enable function may not be available in your current Neovim version
    -- Adding a pcall to safely try to enable the copilot LSP
    pcall(function()
      vim.lsp.enable 'copilot_ls'
    end)
    vim.keymap.set('n', '<Tab>', function()
      -- Try to jump to the start of the suggestion edit.
      -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
      local _ = require('copilot-lsp.nes').walk_cursor_start_edit()
        or (require('copilot-lsp.nes').apply_pending_nes() and require('copilot-lsp.nes').walk_cursor_end_edit())
    end)
  end,
}
