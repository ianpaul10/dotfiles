local H = require 'tests.helpers'
local gitbuf = require 'ipr.gitbuf'
local qf = require 'ipr.quickfix'
local ctx_mod = require 'ipr.ctx'

describe('gitbuf', function()
  it('parses ipr:// uris', function()
    assert.same({ 'abc123', 'src/a b.ts' }, { gitbuf.parse 'ipr://abc123/src/a b.ts' })
    assert.is_nil(gitbuf.parse '/tmp/x.ts')
  end)

  it('opens a deleted file read-only from the merge base', function()
    local dir = H.repo()
    H.write(dir, 'gone.lua', 'return 1\n')
    H.commit(dir, 'add gone')
    H.git(dir, 'switch', '-q', '-c', 'feature')
    H.git(dir, 'rm', '-q', 'gone.lua')
    H.commit(dir, 'remove gone')

    local ctx = assert(ctx_mod.build(dir))
    local files = assert(qf.collect(ctx, false))
    local item = qf.items(ctx, files)[1]
    assert.equals('ipr://' .. ctx.merge_base .. '/gone.lua', item.filename)

    vim.cmd.edit(vim.fn.fnameescape(item.filename))
    assert.same({ 'return 1' }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
    assert.is_false(vim.bo.modifiable)
    assert.equals('lua', vim.bo.filetype)
    vim.cmd 'bwipeout!'
  end)
end)
