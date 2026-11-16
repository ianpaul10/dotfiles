local config = require 'ipr.config'
local frontmatter = require 'ipr.frontmatter'
local git = require 'ipr.git'

local M = {}

---@class IprLink
---@field col_start integer 1-based, inclusive
---@field col_end integer 1-based, inclusive
---@field path string
---@field lnum integer
---@field lnum_end integer

local PATH = '[%w%._%-/@+~]+'
local ns = vim.api.nvim_create_namespace 'ipr_links'

local function looks_like_path(path)
  return path:find '[/.]' ~= nil and not path:match '^%a+://'
end

local function make(col_start, col_end, path, l1, l2)
  path = path:gsub('^%./', '')
  if not looks_like_path(path) then
    return nil
  end
  local lnum = tonumber(l1)
  local lnum_end = tonumber(l2) or lnum
  return { col_start = col_start, col_end = col_end, path = path, lnum = lnum, lnum_end = math.max(lnum, lnum_end) }
end

---`path:12`, `path:12-30`, `path:12:5` (column ignored), `path#L12-L30`
local function parse_ref(text)
  local path, l1, l2 = text:match('^(' .. PATH .. '):(%d+)%-(%d+)$')
  if path then
    return path, l1, l2
  end
  path, l1 = text:match('^(' .. PATH .. '):(%d+)$')
  if path then
    return path, l1
  end
  path, l1 = text:match('^(' .. PATH .. '):(%d+):%d+$')
  if path then
    return path, l1
  end
  path, l1, l2 = text:match('^(' .. PATH .. ')#L(%d+)%-L?(%d+)$')
  if path then
    return path, l1, l2
  end
  return text:match('^(' .. PATH .. ')#L(%d+)$')
end

---Find links on a line: markdown links, backtick spans, then bare path:line.
---@param line string
---@return IprLink[]
function M.parse_line(line)
  local links = {}
  local function overlaps(s, e)
    for _, l in ipairs(links) do
      if s <= l.col_end and e >= l.col_start then
        return true
      end
    end
    return false
  end
  local function add(s, e, text)
    if overlaps(s, e) then
      return
    end
    local path, l1, l2 = parse_ref(text)
    local link = path and make(s, e, path, l1, l2)
    if link then
      table.insert(links, link)
    end
  end

  for s, target, e in line:gmatch '()%[[^%]]*%]%(([^%)%s]+)%)()' do
    add(s, e - 1, target)
  end
  for s, inner, e in line:gmatch '()`([^`]+)`()' do
    add(s, e - 1, vim.trim(inner))
  end
  for s, text, e in line:gmatch('()(' .. PATH .. ':%d+%-?%d*)()') do
    if line:sub(s - 1, s - 1) ~= ':' then
      add(s, e - 1, (text:gsub('%-$', '')))
    end
  end

  table.sort(links, function(a, b)
    return a.col_start < b.col_start
  end)
  return links
end

---@param links IprLink[]
---@param col integer 1-based cursor column
---@return IprLink?
function M.pick(links, col)
  for _, link in ipairs(links) do
    if col >= link.col_start and col <= link.col_end then
      return link
    end
  end
  return links[1]
end

---Absolute path for a link, relative to the review's repo_root.
---@param path string
---@param doc_buf integer
---@param fallback_dir? string directory to find a git root from when there's no frontmatter
function M.resolve(path, doc_buf, fallback_dir)
  if vim.startswith(path, '/') then
    return path
  end
  if vim.startswith(path, '~') then
    return vim.fn.expand(path)
  end
  local root = frontmatter.read_buf(doc_buf).repo_root
  root = root and vim.fn.expand(root) or git.root(fallback_dir or vim.fn.getcwd()) or vim.fn.getcwd()
  local full = root .. '/' .. path
  if vim.fn.filereadable(full) == 1 then
    return full
  end
  -- LLMs sometimes shorten paths despite instructions; accept a unique suffix match.
  local res = git.git({ 'ls-files', '--', '*/' .. path }, root)
  local matches = vim.split(vim.trim(res.stdout), '\n', { trimempty = true })
  if #matches == 1 then
    return root .. '/' .. matches[1]
  end
  return full
end

---Window to show code in: the remembered source window, else the window to
---the left, else a new split on the left.
---@param doc_win integer
---@return integer
function M.target_win(doc_win)
  local doc_buf = vim.api.nvim_win_get_buf(doc_win)
  local tab_wins = vim.api.nvim_tabpage_list_wins(0)
  local function usable(win)
    return win
      and win ~= doc_win
      and vim.api.nvim_win_is_valid(win)
      and vim.tbl_contains(tab_wins, win)
      and vim.bo[vim.api.nvim_win_get_buf(win)].buftype ~= 'quickfix'
  end

  local remembered = vim.b[doc_buf].ipr_source_win
  if usable(remembered) then
    return remembered
  end
  local left = vim.fn.win_getid(vim.fn.winnr 'h')
  if usable(left) then
    vim.b[doc_buf].ipr_source_win = left
    return left
  end
  vim.api.nvim_set_current_win(doc_win)
  vim.cmd 'leftabove vsplit'
  local new = vim.api.nvim_get_current_win()
  vim.b[doc_buf].ipr_source_win = new
  return new
end

local function flash(buf, lnum, lnum_end)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(buf, ns, lnum - 1, 0, { end_row = lnum_end, end_col = 0, hl_group = 'Visual', hl_eol = true })
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    end
  end, 1500)
end

---Open the link under the cursor in the code window.
---@return boolean jumped
function M.jump()
  local doc_win = vim.api.nvim_get_current_win()
  local doc_buf = vim.api.nvim_get_current_buf()
  local col = vim.api.nvim_win_get_cursor(doc_win)[2] + 1
  local link = M.pick(M.parse_line(vim.api.nvim_get_current_line()), col)
  if not link then
    return false
  end

  local win = M.target_win(doc_win)
  local win_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)), ':p:h')
  local file = M.resolve(link.path, doc_buf, vim.fn.isdirectory(win_dir) == 1 and win_dir or nil)
  if vim.fn.filereadable(file) == 0 then
    require('ipr').notify('file not found: ' .. file, vim.log.levels.WARN)
    return true
  end

  vim.api.nvim_set_current_win(win)
  vim.cmd.edit(vim.fn.fnameescape(file))
  local buf = vim.api.nvim_get_current_buf()
  local count = vim.api.nvim_buf_line_count(buf)
  local lnum = math.min(link.lnum, count)
  vim.api.nvim_win_set_cursor(win, { lnum, 0 })
  vim.cmd 'normal! zz'
  flash(buf, lnum, math.min(link.lnum_end, count))
  return true
end

---Move to the next (1) or previous (-1) link in the buffer, wrapping.
---@param direction 1|-1
function M.move(direction)
  local buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2] + 1
  local positions = {}
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    for _, link in ipairs(M.parse_line(line)) do
      table.insert(positions, { i, link.col_start })
    end
  end
  if #positions == 0 then
    return
  end
  local function after(p)
    return p[1] > row or (p[1] == row and p[2] > col)
  end
  local function before(p)
    return p[1] < row or (p[1] == row and p[2] < col)
  end
  local target
  if direction > 0 then
    for _, p in ipairs(positions) do
      if after(p) then
        target = p
        break
      end
    end
    target = target or positions[1]
  else
    for i = #positions, 1, -1 do
      if before(positions[i]) then
        target = positions[i]
        break
      end
    end
    target = target or positions[#positions]
  end
  vim.api.nvim_win_set_cursor(0, { target[1], target[2] - 1 })
end

---All links in a review buffer as quickfix items.
---@param doc_buf integer
function M.items(doc_buf)
  local items = {}
  for i, line in ipairs(vim.api.nvim_buf_get_lines(doc_buf, 0, -1, false)) do
    for _, link in ipairs(M.parse_line(line)) do
      table.insert(items, {
        filename = M.resolve(link.path, doc_buf),
        lnum = link.lnum,
        end_lnum = link.lnum_end,
        text = vim.trim(line),
        user_data = { doc_line = i },
      })
    end
  end
  return items
end

---Review buffer to read links from: the current buffer if it's a review,
---else a visible review window.
local function review_buf()
  local current = vim.api.nvim_get_current_buf()
  if vim.b[current].ipr_review then
    return current
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.b[buf].ipr_review then
      return buf
    end
  end
  return current
end

function M.to_quickfix()
  local buf = review_buf()
  vim.fn.setqflist({}, ' ', {
    title = 'iPR links: ' .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t'),
    items = M.items(buf),
  })
  vim.cmd 'botright copen'
end

local function feed(key)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), 'n', false)
end

---Buffer-local keymaps for a review doc.
---@param bufnr integer
function M.attach(bufnr)
  if vim.b[bufnr].ipr_review then
    return
  end
  vim.b[bufnr].ipr_review = true
  local keys = config.get().keys
  local jump_keys = type(keys.jump) == 'table' and keys.jump or { keys.jump }
  for _, key in ipairs(jump_keys) do
    if key then
      vim.keymap.set('n', key, function()
        if not M.jump() then
          feed(key)
        end
      end, { buffer = bufnr, desc = 'iPR: open link in code window' })
    end
  end
  if keys.next_link then
    vim.keymap.set('n', keys.next_link, function()
      M.move(1)
    end, { buffer = bufnr, desc = 'iPR: next link' })
  end
  if keys.prev_link then
    vim.keymap.set('n', keys.prev_link, function()
      M.move(-1)
    end, { buffer = bufnr, desc = 'iPR: previous link' })
  end
end

return M
