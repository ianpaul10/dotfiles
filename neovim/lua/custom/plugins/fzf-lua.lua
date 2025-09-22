return { -- Fuzzy Finder (files, lsp, etc)
  'ibhagwan/fzf-lua',
  event = 'VimEnter',
  dependencies = {
    { 'nvim-mini/mini.icons' },
  },
  config = function()
    local fzf = require 'fzf-lua'

    fzf.setup {
      defaults = {
        file_icons = 'mini',
      },
      winopts = {
        height = 0.85,
        width = 0.85,
        row = 0.35,
        col = 0.50,
        preview = {
          default = 'builtin',
          layout = 'horizontal',
          horizontal = 'right:50%',
        },
        backdrop = 100,
      },
      keymap = {
        builtin = {
          ['<F1>'] = 'toggle-help',
          ['<C-/>'] = 'toggle-preview',
        },
        fzf = {
          -- use cltr-q to select all items and convert to quickfix list
          ['ctrl-q'] = 'select-all+accept',
        },
      },
      -- File and buffer formatters
      files = {
        formatter = 'path.filename_first',
        git_icons = true,
        file_icons = vim.g.have_nerd_font,
        color_icons = true,
        fd_opts = '--type f --hidden --follow --exclude .git',
      },
      grep = {
        rg_opts = '--hidden --column --line-number --no-heading --color=always --smart-case --max-columns=4096 --glob=!.git/ --glob=!node_modules/ -e',
        file_icons = vim.g.have_nerd_font,
        color_icons = true,
        rg_glob = true, -- enable glob parsing
        glob_flag = '--iglob', -- case insensitive globs
        glob_separator = '%s%s', -- query separator pattern (lua): '  '
      },
      oldfiles = {
        cwd_only = true,
        include_current_session = true,
      },
      previewers = {
        builtin = {
          -- fzf-lua is very fast, but it can struggle with very large files
          syntax_limit_b = 1024 * 100, -- 100KB
        },
      },
    }

    vim.keymap.set('n', '<leader>sh', fzf.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', fzf.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sf', fzf.files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>ss', fzf.builtin, { desc = '[S]earch [S]elect FzfLua' })
    vim.keymap.set('n', '<leader>sw', fzf.grep_cword, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sg', fzf.live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', fzf.diagnostics_workspace, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', fzf.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>s.', fzf.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader>so', fzf.buffers, { desc = '[ ] Find existing open buffers' })
    -- Using oldfiles for frecency-like behavior (most recent first)
    vim.keymap.set('n', '<leader><leader>', function()
      fzf.oldfiles { cwd = vim.fn.getcwd(), prompt = 'Recent Files> ' }
    end, { desc = '[S]earch recent files' })

    vim.keymap.set('n', '<leader>sF', function()
      fzf.files {
        no_ignore = false,
      }
    end, { desc = '[S]earch [F]iles (including hidden files)' })

    -- Slightly advanced example of overriding default behavior and theme
    vim.keymap.set('n', '<leader>/', function()
      fzf.blines { profile = 'ivy' }
    end, { desc = '[/] Fuzzily search in current buffer' })

    vim.keymap.set('n', '<leader>s/', function()
      fzf.live_grep {
        -- Only search in open buffers
        cmd = 'rg --color=always --smart-case --max-columns=4096 -e',
        prompt = 'Live Grep in Open Files> ',
        -- Get list of open buffer files
        cwd_list = vim.tbl_map(
          function(buf)
            return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':p:h')
          end,
          vim.tbl_filter(function(buf)
            return vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf)
          end, vim.api.nvim_list_bufs())
        ),
      }
    end, { desc = '[S]earch [/] in Open Files' })

    vim.keymap.set('n', '<leader>sn', function()
      fzf.files { cwd = vim.fn.stdpath 'config' }
    end, { desc = '[S]earch [N]eovim files' })
  end,
}
