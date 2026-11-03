-- Read-only buffers for file contents at a git revision: ipr://<rev>/<path>
local git = require 'ipr.git'

local M = {}

---@type table<string, string> rev -> repo root
M.roots = {}

---@param root string
---@param rev string
---@param path string
---@return string
function M.uri(root, rev, path)
  M.roots[rev] = root
  return 'ipr://' .. rev .. '/' .. path
end

---@param name string
---@return string? rev, string? path
function M.parse(name)
  return name:match '^ipr://(%x+)/(.+)$'
end

---BufReadCmd handler.
---@param bufnr integer
function M.read(bufnr)
  local rev, path = M.parse(vim.api.nvim_buf_get_name(bufnr))
  if not rev then
    return
  end
  local root = M.roots[rev] or git.root(vim.fn.getcwd())
  local res = git.git({ 'show', rev .. ':' .. path }, root)
  local lines = vim.split(res.ok and res.stdout or res.stderr, '\n', { plain = true })
  if lines[#lines] == '' then
    table.remove(lines)
  end

  local bo = vim.bo[bufnr]
  bo.modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  bo.buftype = 'nofile'
  bo.swapfile = false
  bo.modifiable = false
  bo.readonly = true
  bo.modified = false
  local ft = vim.filetype.match { filename = path, buf = bufnr }
  if ft then
    bo.filetype = ft
  end
end

return M
