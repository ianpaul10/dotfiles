local H = require 'tests.helpers'
local signs = require 'ipr.signs'
local ipr = require 'ipr'
local config = require 'ipr.config'
local ctx_mod = require 'ipr.ctx'

describe('signs', function()
  local calls, ctx

  before_each(function()
    calls = {}
    package.loaded.gitsigns = {
      change_base = function(base, global)
        table.insert(calls, { 'change_base', base, global })
      end,
      reset_base = function(global)
        table.insert(calls, { 'reset_base', global })
      end,
    }
    signs.base = nil
    config.setup {}
    local dir = H.repo()
    H.git(dir, 'switch', '-q', '-c', 'feature')
    H.write(dir, 'a.txt', 'a\n')
    H.commit(dir, 'a')
    vim.cmd.cd(dir)
    ctx = assert(ctx_mod.build(dir))
  end)

  after_each(function()
    package.loaded.gitsigns = nil
  end)

  it('toggles gitsigns between the merge-base and the index, globally', function()
    vim.cmd 'IPR signs'
    assert.is_true(signs.is_on())
    assert.equals(ctx.merge_base, signs.base)
    vim.cmd 'IPR signs'
    assert.is_false(signs.is_on())
    assert.same({ { 'change_base', ctx.merge_base, true }, { 'reset_base', true } }, calls)
  end)

  it('supports explicit on/off, and on refreshes when already on', function()
    vim.cmd 'IPR signs on'
    vim.cmd 'IPR signs on'
    vim.cmd 'IPR signs off'
    assert.same({ 'change_base', 'change_base', 'reset_base' }, vim.tbl_map(function(c)
      return c[1]
    end, calls))
  end)

  it('rejects unknown actions', function()
    signs.command { 'sideways' }
    assert.same({}, calls)
  end)

  it('turns on with :iPR files when signs_on_files is set', function()
    config.setup { signs_on_files = true }
    vim.cmd 'IPR files'
    vim.cmd 'cclose'
    assert.equals(ctx.merge_base, signs.base)
  end)

  it('errors cleanly without gitsigns', function()
    package.loaded.gitsigns = nil
    local saved = package.preload.gitsigns
    package.preload.gitsigns = function()
      error 'not installed'
    end
    signs.on(ctx)
    package.preload.gitsigns = saved
    assert.is_false(signs.is_on())
  end)

  it('completes signs actions', function()
    assert.same({ 'on', 'off' }, ipr.complete('o', 'IPR signs o'))
    assert.same({ 'on', 'off', 'toggle', 'status' }, ipr.complete('', 'IPR signs '))
  end)
end)
