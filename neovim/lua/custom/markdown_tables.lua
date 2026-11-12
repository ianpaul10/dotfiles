-- Aligns GitHub-flavored markdown tables. Inspired by
-- https://heitorpb.github.io/bla/format-tables-in-vim/ but pure Lua, since
-- macOS' BSD `column` lacks `-o` and piping a whole file through it mangles non-table lines.
local M = {}

local function split_cells(line)
  local body = vim.trim(line):gsub('^|', ''):gsub('\\|', '\0'):gsub('|$', '')
  local cells = {}
  for cell in (body .. '|'):gmatch '([^|]*)|' do
    table.insert(cells, vim.trim((cell:gsub('%z', '\\|'))))
  end
  return cells
end

local function is_delimiter_row(cells)
  for _, cell in ipairs(cells) do
    if not cell:match '^:?%-+:?$' then
      return false
    end
  end
  return #cells > 0
end

local function alignment_of(cell)
  local left, right = cell:sub(1, 1) == ':', cell:sub(-1) == ':'
  if left and right then
    return 'center'
  elseif right then
    return 'right'
  end
  return left and 'left' or 'none'
end

local function pad(text, width, align)
  local gap = width - vim.fn.strdisplaywidth(text)
  if align == 'right' then
    return string.rep(' ', gap) .. text
  elseif align == 'center' then
    local left = math.floor(gap / 2)
    return string.rep(' ', left) .. text .. string.rep(' ', gap - left)
  end
  return text .. string.rep(' ', gap)
end

local function delimiter_cell(width, align)
  if align == 'center' then
    return ':' .. string.rep('-', width - 2) .. ':'
  elseif align == 'right' then
    return string.rep('-', width - 1) .. ':'
  elseif align == 'left' then
    return ':' .. string.rep('-', width - 1)
  end
  return string.rep('-', width)
end

local function format_table(rows, indent)
  local column_count = 0
  for _, cells in ipairs(rows) do
    column_count = math.max(column_count, #cells)
  end

  local aligns, widths = {}, {}
  for col = 1, column_count do
    aligns[col] = alignment_of(rows[2][col] or '-')
    widths[col] = 3
    for row_index, cells in ipairs(rows) do
      if row_index ~= 2 then
        widths[col] = math.max(widths[col], vim.fn.strdisplaywidth(cells[col] or ''))
      end
    end
  end

  local formatted = {}
  for row_index, cells in ipairs(rows) do
    local out = {}
    for col = 1, column_count do
      if row_index == 2 then
        out[col] = delimiter_cell(widths[col], aligns[col])
      else
        out[col] = pad(cells[col] or '', widths[col], aligns[col])
      end
    end
    table.insert(formatted, indent .. '| ' .. table.concat(out, ' | ') .. ' |')
  end
  return formatted
end

function M.format_lines(lines)
  local result, block = {}, {}
  local in_fence = false

  local function flush()
    local rows = vim.tbl_map(split_cells, block)
    if #rows >= 2 and is_delimiter_row(rows[2]) then
      vim.list_extend(result, format_table(rows, block[1]:match '^%s*'))
    else
      vim.list_extend(result, block)
    end
    block = {}
  end

  for _, line in ipairs(lines) do
    if line:match '^%s*```' or line:match '^%s*~~~' then
      in_fence = not in_fence
    end
    if not in_fence and line:match '^%s*|' then
      table.insert(block, line)
    else
      flush()
      table.insert(result, line)
    end
  end
  flush()
  return result
end

-- Conform custom formatter spec
M.conform_formatter = {
  format = function(_, _, lines, callback)
    callback(nil, M.format_lines(lines))
  end,
}

return M
