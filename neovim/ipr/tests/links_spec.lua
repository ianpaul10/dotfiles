local H = require 'tests.helpers'
local links = require 'ipr.links'
local config = require 'ipr.config'

local function refs(line)
  return vim.tbl_map(function(l)
    return { l.path, l.lnum, l.lnum_end }
  end, links.parse_line(line))
end

describe('links.parse_line', function()
  it('parses backtick refs with lines and ranges', function()
    assert.same({ { 'src/a.ts', 42, 42 }, { 'src/b.rb', 10, 20 } }, refs 'see `src/a.ts:42` and `src/b.rb:10-20`')
  end)

  it('parses markdown links with GitHub anchors', function()
    assert.same({ { 'src/a.ts', 5, 9 }, { 'lib/x.lua', 3, 3 } }, refs '[hydrate](src/a.ts#L5-L9) and [x](lib/x.lua#L3)')
  end)

  it('parses bare path:line and ignores line:col suffixes', function()
    assert.same({ { 'app/models/shop.rb', 12, 12 }, { 'a/b.ts', 7, 7 } }, refs 'bare app/models/shop.rb:12, then `a/b.ts:7:3`')
  end)

  it('strips ./ and ignores non-paths, urls and plain code spans', function()
    assert.same({ { 'x/y.ts', 1, 1 } }, refs '`./x/y.ts:1` at 10:30 https://host.com:443/x `hydrateCartUi` `foo:3`')
  end)

  it('reports 1-based inclusive columns for the whole span', function()
    local link = links.parse_line('ab `x/y.ts:1` z')[1]
    assert.same({ 4, 13 }, { link.col_start, link.col_end })
  end)

  it('picks the link under the cursor, else the first', function()
    local parsed = links.parse_line '`a/1.ts:1` `b/2.ts:2`'
    assert.equals('b/2.ts', links.pick(parsed, 14).path)
    assert.equals('a/1.ts', links.pick(parsed, 11).path)
  end)
end)

describe('links in a review buffer', function()
  local repo, doc_path

  before_each(function()
    vim.cmd 'silent! %bwipeout!'
    config.setup {}
    repo = H.repo()
    H.write(repo, 'src/a.ts', H.lines(50))
    H.write(repo, 'src/b.ts', H.lines(5))
    doc_path = vim.fn.tempname() .. '.md'
    H.write(vim.fs.dirname(doc_path), vim.fs.basename(doc_path), table.concat({
      '---',
      'repo_root: ' .. repo,
      '---',
      '1. `src/a.ts:20-22` does a thing',
      'plain line',
      '- [ ] [b](src/b.ts#L3) check',
    }, '\n'))
  end)

  local function open_doc()
    vim.cmd.edit(vim.fn.fnameescape(repo .. '/README.md'))
    local code_win = vim.api.nvim_get_current_win()
    vim.cmd('botright vsplit ' .. vim.fn.fnameescape(doc_path))
    links.attach(vim.api.nvim_get_current_buf())
    return code_win, vim.api.nvim_get_current_win()
  end

  it('jumps to the link in the window on the left', function()
    local code_win, doc_win = open_doc()
    vim.api.nvim_win_set_cursor(doc_win, { 4, 0 })
    assert.is_true(links.jump())
    assert.equals(code_win, vim.api.nvim_get_current_win())
    assert.equals(repo .. '/src/a.ts', vim.fn.resolve(vim.api.nvim_buf_get_name(0)))
    assert.equals(20, vim.api.nvim_win_get_cursor(0)[1])
    assert.equals(2, #vim.api.nvim_tabpage_list_wins(0))
  end)

  it('creates a left split when the doc is the only window', function()
    vim.cmd.edit(vim.fn.fnameescape(doc_path))
    vim.cmd 'only'
    vim.api.nvim_win_set_cursor(0, { 6, 0 })
    assert.is_true(links.jump())
    assert.equals(2, #vim.api.nvim_tabpage_list_wins(0))
    assert.equals(repo .. '/src/b.ts', vim.fn.resolve(vim.api.nvim_buf_get_name(0)))
    assert.equals(3, vim.api.nvim_win_get_cursor(0)[1])
  end)

  it('returns false on lines without links', function()
    local _, doc_win = open_doc()
    vim.api.nvim_win_set_cursor(doc_win, { 5, 0 })
    assert.is_false(links.jump())
  end)

  it('moves between links with wrap-around', function()
    local _, doc_win = open_doc()
    vim.api.nvim_win_set_cursor(doc_win, { 1, 0 })
    links.move(1)
    assert.same({ 4, 3 }, vim.api.nvim_win_get_cursor(0))
    links.move(1)
    assert.same({ 6, 6 }, vim.api.nvim_win_get_cursor(0))
    links.move(1)
    assert.same({ 4, 3 }, vim.api.nvim_win_get_cursor(0))
    links.move(-1)
    assert.same({ 6, 6 }, vim.api.nvim_win_get_cursor(0))
  end)

  it('resolves shortened paths by unique suffix', function()
    H.write(repo, 'deep/nested/only.ts', 'x\n')
    H.write(repo, 'one/dup.ts', 'x\n')
    H.write(repo, 'two/dup.ts', 'x\n')
    H.commit(repo, 'more files')
    local _, doc_win = open_doc()
    local buf = vim.api.nvim_win_get_buf(doc_win)
    assert.equals(repo .. '/deep/nested/only.ts', links.resolve('nested/only.ts', buf))
    assert.equals(repo .. '/dup.ts', links.resolve('dup.ts', buf))
  end)

  it('lists every link in quickfix, from the code window too', function()
    local code_win = open_doc()
    vim.api.nvim_set_current_win(code_win)
    links.to_quickfix()
    local items = vim.fn.getqflist()
    assert.equals(2, #items)
    assert.equals(20, items[1].lnum)
    assert.equals(22, items[1].end_lnum)
    assert.equals(repo .. '/src/b.ts', vim.fn.resolve(vim.api.nvim_buf_get_name(items[2].bufnr)))
    vim.cmd 'cclose'
  end)
end)
