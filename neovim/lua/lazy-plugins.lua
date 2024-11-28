-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require('lazy').setup({

  -- NOTE: Plugins that came with kickstart, just reorganized a bit
  require 'kickstart.plugins.which-key',

  require 'kickstart.plugins.neovim-lsp',
  require 'kickstart.plugins.autoformat',
  require 'kickstart.plugins.autocompletion',
  require 'kickstart.plugins.colorscheme',
  require 'kickstart.plugins.color-comments',
  require 'kickstart.plugins.mini-vim',

  require 'kickstart.plugins.debug',
  require 'kickstart.plugins.indent_line',
  -- require 'kickstart.plugins.lint',
  -- require 'kickstart.plugins.autopairs', -- using mini.pairs instead
  -- require 'kickstart.plugins.neo-tree', -- use :Ex and :Lexplore instead and oil.nvim
  require 'kickstart.plugins.gitsigns',

  require 'kickstart.plugins.telescope',
  require 'kickstart.plugins.tree-sitter',

  -- 'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  'ryanoasis/vim-devicons',

  -- NOTE: Custom plugins
  require 'custom.plugins.arrow',
  require 'custom.plugins.undo-tree',
  require 'custom.plugins.fugitive',
  require 'custom.plugins.supermaven',
  -- require 'custom.plugins.groq-and-roll', -- haven't used this in a while, using avante and aider instead
  require 'custom.plugins.avante',
  require 'custom.plugins.comments', -- specifically for ts/tsx comments
}, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
