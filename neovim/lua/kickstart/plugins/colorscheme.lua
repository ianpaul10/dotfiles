local night_owl = {
  'oxfist/night-owl.nvim',
  -- dir = '~/code/night-owl.nvim/', -- custom fork of night-owl with specific ruby config
  priority = 1000, -- make sure to load this before all the other start plugins
  config = function()
    require('night-owl').setup {
      italics = false, -- only diff from default
      bold = true,
      undercurl = true,
      underline = true,
      transparent_background = false,
    }

    vim.cmd.colorscheme 'night-owl'
    -- also setting borders around windows in vim-options.lua
  end,
}

local tokyo_night = {
  'folke/tokyonight.nvim',
  lazy = false,
  priority = 1000,
  opts = {},
  config = function()
    require('tokyonight').setup {
      styles = {
        keywords = { italic = false },
        comments = { italic = false },
        functions = { italic = false },
        variables = { italic = false },
      },
    }

    -- 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
    vim.cmd.colorscheme 'tokyonight-night'
  end,
}

local kanagawa = {
  'rebelot/kanagawa.nvim',
  config = function()
    require('kanagawa').setup {
      compile = false, -- enable compiling the colorscheme
      undercurl = true,
      commentStyle = { italic = false },
      functionStyle = { italic = false },
      keywordStyle = { italic = false },
      statementStyle = { bold = true },
      typeStyle = {},
      transparent = false, -- do not set background color
      dimInactive = false, -- dim inactive window `:h hl-NormalNC`
      terminalColors = true, -- define vim.g.terminal_color_{0,17}
      colors = { -- add/modify theme and palette colors
        palette = {
          -- NOTE: updating default bg values to make them slightly darker for higher contrast
          -- sumiInk0 -> for statusline & floating windows, prev darker, now lighter
          -- sumiInk3 -> for background, prev lighter, now darker
          -- sumiInk0 = '#21212c', -- prev #16161D
          -- sumiInk3 = '#1F1F28', -- prev #363646, other default in the colorscheme, lower contrast
          -- sumiInk3 = '#070821', -- darker & more bluey blue pulled directly from the photo, higher contrast
          sumiInk3 = '#1A1B26', -- tokyonight-night background color, better contrast without being too blue
        },
        theme = {
          wave = {},
          lotus = {},
          dragon = {},
          all = {
            ui = {
              bg_gutter = 'none',
            },
          },
        },
      },
      overrides = function(colors) -- add/modify highlights
        -- kudos https://github.com/rebelot/kanagawa.nvim/issues/216
        return {
          ['@variable.builtin'] = { italic = false },
        }
      end,
      theme = 'wave', -- wave/dragon/lotus set via backgroundsom
      background = {
        dark = 'wave', -- vim.o.background = "dark"
        light = 'lotus', -- vim.o.background = "light"
      },
    }

    -- setup must be called before loading
    vim.cmd.colorscheme 'kanagawa'
  end,
}

local catppuccin = {
  'catppuccin/nvim',
  name = 'catppuccin',
  lazy = false,
  priority = 1000,
  config = function()
    require('catppuccin').setup {
      flavour = 'mocha', -- latte, frappe, macchiato, mocha
      no_italic = true,
    }

    vim.cmd.colorscheme 'catppuccin'
  end,
}

-- night-owl doesn't work perfectly with ruby, so swapping back to tokyo_night for now
return kanagawa
