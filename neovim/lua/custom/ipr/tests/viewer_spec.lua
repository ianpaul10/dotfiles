local H = require 'tests.helpers'
local viewer = require 'ipr.viewer'
local config = require 'ipr.config'
local ctx_mod = require 'ipr.ctx'

local function setup()
  local reviews = vim.fn.tempname()
  config.setup { reviews_dir = reviews }
  local dir = H.repo()
  H.git(dir, 'switch', '-q', '-c', 'feature')
  H.write(dir, 'a.txt', 'a\n')
  H.commit(dir, 'a')
  return assert(ctx_mod.build(dir)), reviews
end

local function review(reviews, name, head_sha)
  H.write(reviews, name, '---\nhead_sha: ' .. head_sha .. '\n---\n# Review\n')
  return reviews .. '/' .. name
end

describe('viewer.find', function()
  it('returns reviews for this repo and branch only, newest first', function()
    local ctx, reviews = setup()
    local older = review(reviews, '2026_01_01_' .. ctx.repo .. '_feature_aaaa.md', 'aaaa')
    vim.uv.fs_utime(older, 1, 1)
    local newer = review(reviews, '2026_01_02_' .. ctx.repo .. '_feature_bbbb.md', 'bbbb')
    review(reviews, '2026_01_03_' .. ctx.repo .. '_feature_sub_cccc.md', 'cccc')
    review(reviews, '2026_01_03_otherrepo_feature_dddd.md', 'dddd')
    assert.same({ newer, older }, viewer.find(ctx))
  end)
end)

describe('viewer.open', function()
  after_each(function()
    vim.cmd 'silent! only'
  end)

  it('opens a right split at half width and remembers the source window', function()
    local ctx, reviews = setup()
    local path = review(reviews, '2026_01_01_' .. ctx.repo .. '_feature_x.md', ctx.head_sha)
    local source = vim.api.nvim_get_current_win()
    viewer.open(path, ctx)
    assert.equals(2, #vim.api.nvim_tabpage_list_wins(0))
    assert.equals(vim.fn.resolve(path), vim.fn.resolve(vim.api.nvim_buf_get_name(0)))
    assert.equals(source, vim.b.ipr_source_win)
    assert.is_true(math.abs(vim.api.nvim_win_get_width(0) - math.floor(vim.o.columns / 2)) <= 1)
    assert.is_nil(vim.b.ipr_stale_warned)
  end)

  it('reuses an existing window for the same review', function()
    local ctx, reviews = setup()
    local path = review(reviews, '2026_01_01_' .. ctx.repo .. '_feature_x.md', ctx.head_sha)
    viewer.open(path, ctx)
    vim.cmd 'wincmd p'
    viewer.open(path, ctx)
    assert.equals(2, #vim.api.nvim_tabpage_list_wins(0))
  end)

  it('warns when the review is for an older HEAD', function()
    local ctx, reviews = setup()
    local path = review(reviews, '2026_01_01_' .. ctx.repo .. '_feature_x.md', 'deadbeef')
    viewer.open(path, ctx)
    assert.is_true(vim.b.ipr_stale_warned)
  end)
end)
