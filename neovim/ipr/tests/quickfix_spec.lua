local H = require 'tests.helpers'
local qf = require 'ipr.quickfix'
local ctx_mod = require 'ipr.ctx'

local function fixture()
  local dir = H.repo()
  H.write(dir, 'keep.txt', H.lines(10))
  H.write(dir, 'gone.txt', H.lines(4, 'doomed'))
  H.write(dir, 'old_name.txt', H.lines(20, 'stable'))
  H.commit(dir, 'base files')
  H.git(dir, 'switch', '-q', '-c', 'feature')
  local keep = H.lines(10):gsub('line 3\n', 'line three\n'):gsub('line 10\n', 'line 10\nline 11\nline 12\n')
  H.write(dir, 'keep.txt', keep)
  H.write(dir, 'added.txt', H.lines(5, 'fresh'))
  H.git(dir, 'rm', '-q', 'gone.txt')
  H.git(dir, 'mv', 'old_name.txt', 'new_name.txt')
  H.commit(dir, 'feature')
  return dir
end

local function by_path(files)
  local out = {}
  for _, f in ipairs(files) do
    out[f.path] = f
  end
  return out
end

describe('quickfix.collect', function()
  it('reports status and +/-/~ counts per file', function()
    local dir = fixture()
    local ctx = assert(ctx_mod.build(dir))
    local files = by_path(assert(qf.collect(ctx, false)))

    assert.equals('M', files['keep.txt'].status)
    assert.same({ 2, 0, 1 }, { files['keep.txt'].added, files['keep.txt'].removed, files['keep.txt'].changed })
    assert.equals('A', files['added.txt'].status)
    assert.equals(5, files['added.txt'].added)
    assert.equals('D', files['gone.txt'].status)
    assert.equals(4, files['gone.txt'].removed)
    assert.equals('R', files['new_name.txt'].status)
    assert.equals('old_name.txt', files['new_name.txt'].old_path)
  end)

  it('includes uncommitted and untracked changes with include_worktree', function()
    local dir = fixture()
    H.write(dir, 'scratch.txt', 'x\n')
    H.write(dir, 'added.txt', H.lines(6, 'fresh'))
    local ctx = assert(ctx_mod.build(dir))
    assert.equals(5, by_path(assert(qf.collect(ctx, false)))['added.txt'].added)
    local files = by_path(assert(qf.collect(ctx, true)))
    assert.equals(6, files['added.txt'].added)
    assert.equals('?', files['scratch.txt'].status)
  end)
end)

describe('quickfix formatting', function()
  it('aligns columns and shows renames', function()
    assert.equals(
      'M     +12     -3     ~4  src/foo.ts',
      qf.format { status = 'M', path = 'src/foo.ts', added = 12, removed = 3, changed = 4, hunks = {} }
    )
    assert.equals(
      'R                    ~1  a.ts → b.ts',
      qf.format { status = 'R', old_path = 'a.ts', path = 'b.ts', added = 0, removed = 0, changed = 1, hunks = {} }
    )
  end)

  it('builds items that jump to the first hunk', function()
    local dir = fixture()
    local ctx = assert(ctx_mod.build(dir))
    local items = qf.items(ctx, assert(qf.collect(ctx, false)))
    local keep = vim.tbl_filter(function(i)
      return i.user_data.path == 'keep.txt'
    end, items)[1]
    assert.equals(dir .. '/keep.txt', keep.filename)
    assert.equals(3, keep.lnum)
  end)

  it('renders the quickfix window with the textfunc', function()
    local dir = fixture()
    vim.cmd.cd(dir)
    qf.open(false)
    H.wait_qf()
    local title = vim.fn.getqflist({ title = 1 }).title
    assert.matches('^iPR: feature ← main %(via default%) · 4 files', title)
    local lines = vim.api.nvim_buf_get_lines(vim.fn.getqflist({ qfbufnr = 1 }).qfbufnr, 0, -1, false)
    assert.equals('A      +5                added.txt', lines[1])
    vim.cmd 'cclose'
  end)
end)

describe('quickfix uncommitted', function()
  local function dirty_fixture()
    local dir = fixture()
    H.write(dir, 'keep.txt', H.lines(10):gsub('line 3\n', 'line three\n'):gsub('line 5\n', 'line five\n'))
    H.write(dir, 'staged.txt', 'staged\n')
    H.git(dir, 'add', 'staged.txt')
    H.write(dir, 'scratch.txt', 'x\n')
    H.git(dir, 'rm', '-q', 'added.txt')
    return dir
  end

  it('lists only changes vs HEAD, including staged, deleted and untracked', function()
    local dir = dirty_fixture()
    local files = by_path(assert(qf.collect_range(dir, 'HEAD', nil)))
    local paths = vim.tbl_keys(files)
    table.sort(paths)
    assert.same({ 'added.txt', 'keep.txt', 'scratch.txt', 'staged.txt' }, paths)
    assert.equals('M', files['keep.txt'].status)
    assert.equals(1, files['keep.txt'].changed)
    assert.equals('A', files['staged.txt'].status)
    assert.equals('D', files['added.txt'].status)
    assert.equals('?', files['scratch.txt'].status)
  end)

  it('opens deleted files from HEAD', function()
    local dir = dirty_fixture()
    vim.cmd.cd(dir)
    vim.cmd 'IPR uncommitted'
    H.wait_qf()
    local list = vim.fn.getqflist { title = 1, items = 1 }
    assert.matches('^iPR: uncommitted on feature · 4 files', list.title)
    local head = H.git(dir, 'rev-parse', 'HEAD')
    local deleted = vim.tbl_filter(function(i)
      return i.user_data.path == 'added.txt'
    end, list.items)[1]
    assert.equals('ipr://' .. head .. '/added.txt', vim.api.nvim_buf_get_name(deleted.bufnr))
    vim.cmd 'cclose'
  end)

  it('says so when the tree is clean', function()
    local dir = fixture()
    vim.cmd.cd(dir)
    vim.cmd 'IPR uncommitted'
    H.wait_qf()
    assert.equals('iPR: no uncommitted changes on feature', vim.fn.getqflist({ title = 1 }).title)
    vim.cmd 'cclose'
  end)
end)
