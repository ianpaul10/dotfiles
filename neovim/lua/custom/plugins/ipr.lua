-- iPR: local-first PR review. Source lives in neovim/ipr (standalone plugin
-- layout, kept outside lua/ so its modules only resolve as `ipr.*`).
return {
  dir = vim.fn.stdpath 'config' .. '/ipr',
  name = 'ipr',
  lazy = false,
  opts = {},
}
