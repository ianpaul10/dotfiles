-- Minimal YAML frontmatter reader: flat `key: value` pairs only.
local M = {}

---@param lines string[]
---@return table<string, string>
function M.parse(lines)
  local out = {}
  if lines[1] ~= '---' then
    return out
  end
  for i = 2, math.min(#lines, 60) do
    local line = lines[i]
    if line == '---' then
      break
    end
    local key, value = line:match '^([%w_]+):%s*(.-)%s*$'
    if key then
      out[key] = value:gsub('^["\'](.*)["\']$', '%1')
    end
  end
  return out
end

---@param path string
function M.read_file(path)
  if vim.fn.filereadable(path) == 0 then
    return {}
  end
  return M.parse(vim.fn.readfile(path, '', 60))
end

---@param bufnr integer
function M.read_buf(bufnr)
  return M.parse(vim.api.nvim_buf_get_lines(bufnr, 0, 60, false))
end

return M
