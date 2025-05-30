-- Telescope is a fuzzy finder that comes with a lot of different things that
-- it can fuzzy find! It's more than just a "file finder", it can search
-- many different aspects of Neovim, your workspace, LSP, and more!
--
-- The easiest way to use Telescope, is to start by doing something like:
--  :Telescope help_tags
--
-- After running this command, a window will open up and you're able to
-- type in the prompt window. You'll see a list of `help_tags` options and
-- a corresponding preview of the help.
--
-- Two important keymaps to use while in Telescope are:
--  - Insert mode: <c-/>
--  - Normal mode: ?
--
-- This opens a window that shows you all of the keymaps for the current
-- Telescope picker. This is really useful to discover what Telescope can
-- do as well as how to actually do it!

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`

local live_multi_grep = function(opts)
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local make_entry = require 'telescope.make_entry'
  local conf = require('telescope.config').values

  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()

  local finder = finders.new_async_job {
    command_generator = function(prompt)
      if not prompt or prompt == '' then
        return nil
      end

      -- NOTE: TWO spaces to split the first and second piece of the command
      -- resulting rg command:
      -- rg -e <regex> --hidden -g <glob> --color=never --no-heading --with-filename --line-number --column --smart-case
      -- example glob can be something like *.txt or *.lua for file filters, or **/*test*/** for dir filters

      local pieces = vim.split(prompt, '  ')
      local args = { 'rg' }

      if pieces[1] then
        table.insert(args, '-e') -- regex
        table.insert(args, pieces[1])
      end

      if pieces[2] then
        table.insert(args, '--hidden')
        table.insert(args, '-g') -- glob
        table.insert(args, pieces[2])
      end

      if pieces[3] then
        table.insert(args, '-g') -- glob
        table.insert(args, pieces[3])
      end

      return vim.tbl_flatten {
        args,
        {
          '--color=never',
          '--no-heading',
          '--with-filename',
          '--line-number',
          '--column',
          '--smart-case',
        },
      }
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  }

  pickers
    .new(opts, {
      debounce = 100,
      prompt_title = 'Multi Grep (filter by file after two spaces)',
      finder = finder,
      previewer = conf.grep_previewer(opts),
      sorter = require('telescope.sorters').empty(),
    })
    :find()
end

return { -- Fuzzy Finder (files, lsp, etc)
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { -- If encountering errors, see telescope-fzf-native README for installation instructions
      'nvim-telescope/telescope-fzf-native.nvim',

      -- `build` is used to run some command when the plugin is installed/updated.
      -- This is only run then, not every time Neovim starts up.
      build = 'make',

      -- `cond` is a condition used to determine whether this plugin should be
      -- installed and loaded.
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },

    -- Useful for getting pretty icons, but requires a Nerd Font.
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    -- { 'echasnovski/mini.icons', enabled = vim.g.have_nerd_font }, -- mini.icons don't seem to work
    {
      'nvim-telescope/telescope-frecency.nvim',
      version = '*',
      config = function()
        require('telescope').load_extension 'frecency'
      end,
    },
  },
  config = function()
    require('telescope').setup {
      -- You can put your default mappings / updates / etc. in here
      --  All the info you're looking for is in `:help telescope.setup()`
      defaults = {
        -- mappings = {
        --   i = { ['<c-enter>'] = 'to_fuzzy_refine' },
        -- },
        -- Format path as "file.txt (path\to\file\)"
        path_display = function(opts, path)
          local tail = require('telescope.utils').path_tail(path)

          -- NOTE: extracts relative path (:.) to cwd and then extracts the non-file path part (:h or :head)
          local rel_path = vim.fn.fnamemodify(vim.fn.fnamemodify(path, ':.'), ':h')
          return string.format('%s [%s]', tail, rel_path)
        end,
      },
      -- pickers = {}
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
        fzf = {},
        frecency = {},
      },
    }

    -- Enable Telescope extensions if they are installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')
    pcall(require('telescope').load_extension, 'frecency')

    -- See `:help telescope.builtin`
    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    -- vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>slg', builtin.live_grep, { desc = '[S]earch by default [L]ive [G]rep (default telescope imp.)' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader>so', builtin.buffers, { desc = '[ ] Find existing open buffers' })
    vim.keymap.set('n', '<leader><leader>', ':Telescope frecency workspace=CWD show_scores=true <CR>', { desc = '[S]earch frecent files' })

    vim.keymap.set('n', '<leader>sF', function()
      builtin.find_files {
        -- source: https://github.com/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes#file-and-text-search-in-hidden-files-and-directories
        -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d, so we're using `--glob` to exclude it.
        find_command = { 'rg', '--files', '--hidden', '--glob', '!**/.git/*' },
      }
    end, { desc = '[S]earch [F]iles (including hidden files)' })

    -- NOTE: multigrep across all files in the current directory.
    -- First part of the prompt is the search term, second part is the file glob, separated by two spaces.
    vim.keymap.set('n', '<leader>sg', function(opts)
      live_multi_grep(opts)
    end, { desc = '[S]earch by [G]rep (multigrep)' })

    -- Slightly advanced example of overriding default behavior and theme
    vim.keymap.set('n', '<leader>/', function()
      -- You can pass additional configuration to Telescope to change the theme, layout, etc.
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    -- It's also possible to pass additional configuration options.
    --  See `:help telescope.builtin.live_grep()` for information about particular keys
    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[S]earch [/] in Open Files' })

    -- Shortcut for searching your Neovim configuration files
    vim.keymap.set('n', '<leader>sn', function()
      builtin.find_files { cwd = vim.fn.stdpath 'config' }
    end, { desc = '[S]earch [N]eovim files' })
  end,
}
