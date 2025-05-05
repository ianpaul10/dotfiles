return {
  'nvim-lua/plenary.nvim',
  config = function()
    local terminal_buf = nil
    local terminal_win = nil

    local function toggle_terminal()
      -- If terminal window exists, close it & return
      if terminal_win ~= nil and vim.api.nvim_win_is_valid(terminal_win) then
        vim.api.nvim_win_close(terminal_win, true)
        terminal_win = nil
        return
      end
      -- If terminal buffer doesn't exist, create it without changing the current buffer
      if terminal_buf == nil or not vim.api.nvim_buf_is_valid(terminal_buf) then
        local current_win = vim.api.nvim_get_current_win()

        -- Create a temporary split to create the terminal buffer
        vim.cmd 'botright vnew'
        terminal_buf = vim.api.nvim_get_current_buf()
        vim.fn.jobstart(vim.o.shell, { term = true })
        vim.bo[terminal_buf].buflisted = false

        -- NOTE: it says it's deprecated but 'vim.api.nvim_set_option_value('number', true, { buf = terminal_buf })' fails to parse the buf num
        vim.api.nvim_buf_set_option(terminal_buf, 'number', true)
        vim.api.nvim_buf_set_option(terminal_buf, 'relativenumber', true)

        -- Close the temporary window and return to original window
        vim.api.nvim_win_close(0, true)
        vim.api.nvim_set_current_win(current_win)
      end

      local width = math.floor(vim.o.columns * 0.3)

      vim.cmd 'botright vsplit'
      terminal_win = vim.api.nvim_get_current_win()

      vim.api.nvim_win_set_buf(terminal_win, terminal_buf)
      vim.api.nvim_win_set_width(terminal_win, width)

      vim.cmd 'startinsert'
    end

    vim.keymap.set('n', '<leader>a', toggle_terminal, { noremap = true, silent = true, desc = 'Toggle aider terminal' })
  end,
}
