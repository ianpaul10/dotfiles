local header_art_1 = [[
 ╭╮╭┬─╮╭─╮┬  ┬┬╭┬╮
 │││├┤ │ │╰┐┌╯││││
 ╯╰╯╰─╯╰─╯ ╰╯ ┴┴ ┴
]]

local header_art_2 = [[
 __/\\\\\_____/\\\_______________________________/\\\________/\\\___________________________________
 __\/\\\\\\___\/\\\______________________________\/\\\_______\/\\\__________________________________
 ___\/\\\/\\\__\/\\\______________________________\//\\\______/\\\___/\\\___________________________
 ____\/\\\//\\\_\/\\\_____/\\\\\\\\______/\\\\\_____\//\\\____/\\\___\///_____/\\\\\__/\\\\\________
 _____\/\\\\//\\\\/\\\___/\\\/////\\\___/\\\///\\\____\//\\\__/\\\_____/\\\__/\\\///\\\\\///\\\_____
 ______\/\\\_\//\\\/\\\__/\\\\\\\\\\\___/\\\__\//\\\____\//\\\/\\\_____\/\\\_\/\\\_\//\\\__\/\\\____
 _______\/\\\__\//\\\\\\_\//\\///////___\//\\\__/\\\______\//\\\\\______\/\\\_\/\\\__\/\\\__\/\\\___
 ________\/\\\___\//\\\\\__\//\\\\\\\\\\__\///\\\\\/________\//\\\_______\/\\\_\/\\\__\/\\\__\/\\\__
 _________\///_____\/////____\//////////_____\/////___________\///________\///__\///___\///___\///__
]]

return { -- Collection of various small independent plugins/modules
  'echasnovski/mini.nvim',
  config = function()
    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup { n_lines = 500 }

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup()

    -- NOTE: Simple and easy statusline. From left to right:
    -- --
    -- mode
    -- --
    -- git branch icon + branch name  <> file info icon + ('+n ~n -n' for line changes),
    -- beaker icon ('Hn In Wn En' for hints, info, warn, error counts),
    -- circled 'L' for LSP sever count (num of + is number of servers)
    -- --
    -- file name/path
    -- BREAK
    -- filetype, file encoding, file size
    -- --
    -- pos, percentage
    local statusline = require 'mini.statusline'
    -- set use_icons to true if you have a Nerd Font
    statusline.setup { use_icons = vim.g.have_nerd_font }
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '[%l:%v][%p%%]'
    end

    require('mini.icons').setup()

    require('mini.sessions').setup { autoread = false, autowrite = true, directory = '~/.neovim_sessions' }
    local get_session_name = function(incl_branch)
      local dir = vim.fn.fnamemodify(vim.fn.getcwd(), ':t'):gsub('/$', ''):gsub('%.', '')
      local branch = vim.fn.system('git branch --show-current'):gsub('\n', '')
      if not incl_branch then
        return dir
      end
      return dir .. '__' .. branch
    end
    local write_session = function(incl_branch)
      local session_name = get_session_name(incl_branch)
      MiniSessions.write(session_name)
    end
    local read_session = function(incl_branch)
      local session_name = get_session_name(incl_branch)
      MiniSessions.read(session_name)
    end

    vim.keymap.set('n', '<Leader>ww', function()
      write_session(false)
    end, { desc = '[W]rite [w]orkspace to a session (dir)' })
    vim.keymap.set('n', '<Leader>wW', function()
      write_session(true)
    end, { desc = '[W]rite [W]orkspace to a session (dir__branch)' })
    vim.keymap.set('n', '<Leader>wo', function()
      read_session(false)
    end, { desc = '[W]orkspace [o]pen session based on dir' })
    vim.keymap.set('n', '<Leader>wO', function()
      read_session(true)
    end, { desc = '[W]orkspace [o]pen session based on dir__branch' })

    require('mini.starter').setup { header = header_art_2, footer = '' }

    require('mini.files').setup { windows = { preview = true } }
    local minifiles_toggle = function(use_cur_buffer)
      if not MiniFiles.close() then
        if use_cur_buffer then
          MiniFiles.open(vim.api.nvim_buf_get_name(0))
        else
          MiniFiles.open()
        end
      end
    end
    vim.keymap.set('n', '-', function()
      minifiles_toggle(false)
    end, { desc = 'Open mini file explorer' })
    vim.keymap.set('n', '<Leader>-', function()
      minifiles_toggle(true)
    end, { desc = 'Open mini file explorer in current buffer' })

    -- require('mini.notify').setup()
    -- ... and there is more!
    --  Check out: https://github.com/echasnovski/mini.nvim
  end,
}
