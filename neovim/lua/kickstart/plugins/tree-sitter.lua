-- NOTE: Highlight, edit, and navigate code

return {
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    {
      -- NOTE: Treesitter "context" i.e. Freeze the top of the current function/block at the top of the window if it goes beyond the current window
      -- Only freeze a single line for each level of context, for a total of 5 lines of context (if it goes 5 contexts deep)
      'nvim-treesitter/nvim-treesitter-context',
      opts = {
        enable = true,
        max_lines = 5,
        multiline_threshold = 1,
      },
    },
  },
  build = ':TSUpdate',
  opts = {
    ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
    -- Autoinstall languages that are not installed
    auto_install = true,
    highlight = {
      enable = true,
      -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
      --  If you are experiencing weird indenting issues, add the language to
      --  the list of additional_vim_regex_highlighting and disabled languages for indent.
      additional_vim_regex_highlighting = { 'ruby' },
    },
    -- indent = { enable = true, disable = { 'ruby' } }, -- experimental, doesn't work well
  },
  config = function(_, opts)
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`

    -- Prefer git instead of curl in order to improve connectivity in some environments
    require('nvim-treesitter.install').prefer_git = true
    ---@diagnostic disable-next-line: missing-fields
    require('nvim-treesitter.configs').setup(opts)
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  end,
}
