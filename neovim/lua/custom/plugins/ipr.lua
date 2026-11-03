-- iPR: local-first PR review. Source lives in ../ipr (standalone plugin layout).
return {
  dir = vim.fn.stdpath 'config' .. '/lua/custom/ipr',
  name = 'ipr',
  lazy = false,
  opts = {},
}
