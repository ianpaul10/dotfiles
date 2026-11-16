local ipr = require 'ipr'
local config = require 'ipr.config'

describe('ipr', function()
  it('registers the :IPR command', function()
    assert.equals(2, vim.fn.exists ':IPR')
  end)

  it('merges options and replaces list values', function()
    ipr.setup { keys = { jump = { 'gd' }, files = false }, pi_args = { '-p' } }
    local opts = config.get()
    assert.same({ 'gd' }, opts.keys.jump)
    assert.is_false(opts.keys.files)
    assert.same({ '-p' }, opts.pi_args)
    assert.equals('<leader>ipw', opts.keys.walkthrough)
  end)

  it('dispatches to registered subcommands', function()
    local got
    ipr.subcommands.test_sub = {
      desc = 'test',
      run = function(args, bang)
        got = { args = args, bang = bang }
      end,
    }
    vim.cmd 'IPR! test_sub a b'
    assert.same({ args = { 'a', 'b' }, bang = true }, got)
    ipr.subcommands.test_sub = nil
  end)

  it('completes subcommand names', function()
    ipr.subcommands.zzz = { desc = '', run = function() end }
    assert.same({ 'zzz' }, ipr.complete('zz', 'IPR zz'))
    assert.same({}, ipr.complete('', 'IPR zzz '))
    ipr.subcommands.zzz = nil
  end)
end)
