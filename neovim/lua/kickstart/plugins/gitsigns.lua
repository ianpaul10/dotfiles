-- Adds git related signs to the gutter, as well as utilities for managing changes
-- NOTE: gitsigns is already included in init.lua but contains only the base
-- config. This will add also the recommended keymaps.

return {
  'lewis6991/gitsigns.nvim',
  opts = {
    on_attach = function(bufnr)
      local gitsigns = require 'gitsigns'

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal { ']c', bang = true }
        else
          gitsigns.nav_hunk 'next'
        end
      end, { desc = 'Jump to next git [c]hange' })

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal { '[c', bang = true }
        else
          gitsigns.nav_hunk 'prev'
        end
      end, { desc = 'Jump to previous git [c]hange' })

      -- Actions
      -- visual mode
      map('v', '<leader>gs', function()
        gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, { desc = 'stage git hunk' })
      map('v', '<leader>gr', function()
        gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, { desc = 'reset git hunk' })
      -- normal mode
      map('n', '<leader>gh', gitsigns.stage_hunk, { desc = '[G]it stage [h]unk' })
      map('n', '<leader>gr', gitsigns.reset_hunk, { desc = '[G]it [r]eset hunk' })
      map('n', '<leader>gS', gitsigns.stage_buffer, { desc = '[G]it [S]tage buffer' })
      map('n', '<leader>gu', gitsigns.undo_stage_hunk, { desc = '[G]it [u]ndo stage hunk' })
      map('n', '<leader>gR', gitsigns.reset_buffer, { desc = '[G]it [R]eset buffer' })
      map('n', '<leader>gp', gitsigns.preview_hunk, { desc = '[G]it [p]review hunk' })
      map('n', '<leader>gb', gitsigns.blame_line, { desc = '[G]it [b]lame line' })
      map('n', '<leader>gd', gitsigns.diffthis, { desc = '[G]it [d]iff against index' })
      map('n', '<leader>gD', function()
        gitsigns.diffthis '@'
      end, { desc = '[G]it [D]iff against last commit' })
      -- Toggles
      map('n', '<leader>gtb', gitsigns.toggle_current_line_blame, { desc = '[G]it [T]oggle show [b]lame line' })
      map('n', '<leader>gtd', gitsigns.toggle_deleted, { desc = '[G]it [T]oggle show [D]eleted' })

      map('n', '<leader>gn', function()
        gitsigns.nav_hunk 'next'
      end, { desc = '[G]it go to [n]ext hunk' })
      map('n', '<leader>gp', function()
        gitsigns.nav_hunk 'prev'
      end, { desc = '[G]it go to [p]revious hunk' })
    end,
  },
}
