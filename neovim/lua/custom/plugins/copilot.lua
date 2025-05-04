M = {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  config = function()
    vim.keymap.set('n', '<leader>ct', ':Copilot toggle<CR>', { desc = '[C]opilot [t]oggle' })
    vim.keymap.set('n', '<leader>cs', ':Copilot suggestion<CR>', { desc = '[C]opilot [s]uggestion' })
    require('copilot').setup {
      panel = {
        enabled = false,
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        debounce = 75,
        trigger_on_accept = true,
        keymap = {
          accept = '<C-k>',
          accept_word = '<C-j>',
          accept_line = false,
          next = '<C-l>',
          prev = '<C-h>',
          dismiss = '<C-;>',
        },
      },
      filetypes = {
        markdown = true,
        gitcommit = true,
        ruby = true,
        lua = true,
        python = true,
        typescript = true,
        javascript = true,
        yaml = false,
        help = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        -- ['.'] = false,
      },
      copilot_node_command = vim.fn.expand '$HOME' .. '/.nvm/versions/node/v23.10.0/bin/node', -- Node.js version must be > 20
    }
  end,
}
return M
