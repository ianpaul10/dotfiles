-- Change the name of the colorscheme plugin below, and then
-- change the command in the config to whatever the name of that colorscheme is.
-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
return {
  'oxfist/night-owl.nvim',
  -- 'folke/tokyonight.nvim', -- If you want to use tokyonight, you can uncomment this line.
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
