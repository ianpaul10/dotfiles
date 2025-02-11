-- Change the name of the colorscheme plugin below, and then
-- change the command in the config to whatever the name of that colorscheme is.
-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
local night_owl = {
  'oxfist/night-owl.nvim',
  lazy = false, -- make sure we load this during startup if it is your main colorscheme
  priority = 1000, -- make sure to load this before all the other start plugins
  config = function()
    -- load the colorscheme here
    require('night-owl').setup {
      italics = false, -- only diff from default
      bold = true,
      undercurl = true,
      underline = true,
      transparent_background = false,
    }

    vim.cmd.colorscheme 'night-owl'
    -- also setting borders around windows in vim-options.lua

    -- vim.cmd.colorscheme 'slate' -- If you want to use the default slate colorscheme, you can uncomment this line.
  end,
}

local kanagawa = {
  'rebelot/kanagawa.nvim',
  config = function()
    require('kanagawa').setup {
      compile = false, -- enable compiling the colorscheme
      undercurl = true, -- enable undercurls
      commentStyle = { italic = false },
      functionStyle = {},
      keywordStyle = { italic = false },
      statementStyle = { bold = false },
      typeStyle = {},
      transparent = false, -- do not set background color
      dimInactive = false, -- dim inactive window `:h hl-NormalNC`
      terminalColors = true, -- define vim.g.terminal_color_{0,17}
      colors = { -- add/modify theme and palette colors
        palette = {
          -- NOTE: updating default bg values to make them slightly darker for higher contrast
          -- sumiInk0 -> for statusline & floating windows, prev darker, now lighter
          -- sumiInk3 -> for background, prev lighter, now darker
          sumiInk0 = '#21212c', -- prev #16161D
          sumiInk3 = '#16161D', -- prev #363646
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
        return {}
      end,
      -- theme = 'wave', -- wave/dragon/lotus set via background
      background = {
        dark = 'wave', -- vim.o.background = "dark"
        light = 'lotus', -- vim.o.background = "light"
      },
    }

    -- setup must be called before loading
    vim.cmd 'colorscheme kanagawa'
  end,
}

return kanagawa

-- Supposed to be good for colourblind people. I didn't find it high-contrast enough. Night owl is where it's at.
-- return {
--   'EdenEast/nightfox.nvim',
--   lazy = false,
--   priority = 1000,
--   config = function()
--     require('nightfox').setup {
--       options = {
--         colorblind = {
--           enable = true,
--           severity = {
--             protan = 0.9,
--             deutan = 0.3,
--             tritan = 0.0,
--           },
--         },
--       },
--     }
--     vim.cmd.colorscheme 'nightfox'
--   end,
-- }
