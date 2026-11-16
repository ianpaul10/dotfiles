local H = require 'tests.helpers'
local wt = require 'ipr.walkthrough'
local config = require 'ipr.config'
local ctx_mod = require 'ipr.ctx'
local fm = require 'ipr.frontmatter'

-- Fake pi: records its argv and writes (or doesn't write) the output file named in the prompt.
local function fake_pi(behavior)
  local script = vim.fn.tempname() .. '.sh'
  H.write(
    vim.fs.dirname(script),
    vim.fs.basename(script),
    table.concat({
      '#!/usr/bin/env bash',
      'printf "%s\\n" "$@" > "$0.args"',
      'prompt="${@: -1}"',
      [[out=$(printf '%s\n' "$prompt" | sed -n 's/^1\. Write the guide to exactly this file using your write tool: //p')]],
      behavior,
    }, '\n')
  )
  vim.fn.setfperm(script, 'rwxr-xr-x')
  return script
end

local function feature_repo()
  local dir = H.repo()
  H.git(dir, 'switch', '-q', '-c', 'feat/thing')
  H.write(dir, 'a.txt', 'a\n')
  H.commit(dir, 'add a')
  return assert(ctx_mod.build(dir))
end

local function run(ctx)
  wt.start(ctx)
  assert.is_true(vim.wait(5000, function()
    return wt.job == nil
  end, 20))
  return wt.last
end

describe('walkthrough', function()
  local reviews
  before_each(function()
    reviews = vim.fn.tempname()
    wt.last = nil
    wt.confirm = function()
      return true
    end
  end)

  it('names the output by date, repo, branch and sha', function()
    config.setup { reviews_dir = reviews }
    local ctx = feature_repo()
    local path = wt.output_path(ctx, '2026_11_02')
    assert.equals(
      reviews .. '/2026_11_02_' .. ctx.repo .. '_feat-thing_' .. ctx.head_sha:sub(1, 10) .. '.md',
      path
    )
  end)

  it('puts the output contract and frontmatter in the prompt', function()
    config.setup { reviews_dir = reviews }
    local ctx = feature_repo()
    local prompt = wt.build_prompt(ctx, { output_path = '/tmp/out.md', skill_file = '/s/SKILL.md' })
    assert.matches('Read and follow the skill at /s/SKILL.md', prompt, 1, true)
    assert.matches('exactly this file using your write tool: /tmp/out.md', prompt, 1, true)
    assert.matches('head_sha: ' .. ctx.head_sha, prompt, 1, true)
    assert.matches('add a', prompt, 1, true)
  end)

  it('defaults to the bundled skill', function()
    config.setup {}
    local dir, file = wt.skill_paths()
    assert.equals(1, vim.fn.filereadable(file))
    assert.equals(dir .. '/SKILL.md', file)
  end)

  it('runs pi with the skill and validates the written file', function()
    local pi = fake_pi [[printf -- '---\nhead_sha: abc\n---\n# Review\n' > "$out"]]
    config.setup { reviews_dir = reviews, pi_cmd = pi, skill = '/custom/skill' }
    local result = run(feature_repo())
    assert.is_true(result.ok, result.err)
    assert.same({ head_sha = 'abc' }, fm.read_file(result.output_path))
    local args = vim.fn.readfile(pi .. '.args')
    assert.same({ '-p', '--no-session', '--skill', '/custom/skill' }, vim.list_slice(args, 1, 4))
    assert.equals(0, vim.fn.filereadable((result.output_path:gsub('%.md$', '.log'))))
  end)

  it('fails when pi exits non-zero and keeps the log', function()
    config.setup { reviews_dir = reviews, pi_cmd = fake_pi 'echo boom >&2; exit 3' }
    local result = run(feature_repo())
    assert.is_false(result.ok)
    assert.matches('code 3', result.err)
    local log = table.concat(vim.fn.readfile((result.output_path:gsub('%.md$', '.log'))), '\n')
    assert.matches('boom', log)
  end)

  it('fails when pi exits 0 without writing the file', function()
    config.setup { reviews_dir = reviews, pi_cmd = fake_pi 'exit 0' }
    local result = run(feature_repo())
    assert.is_false(result.ok)
    assert.matches('did not write', result.err)
  end)

  it('cancels a running job without reporting failure', function()
    config.setup { reviews_dir = reviews, pi_cmd = fake_pi 'sleep 5' }
    wt.start(feature_repo())
    assert.is_not_nil(wt.job)
    wt.cancel()
    assert.is_nil(wt.job)
    vim.wait(300)
    assert.is_nil(wt.last)
  end)
end)

describe('frontmatter.parse', function()
  it('reads flat key/value pairs and strips quotes', function()
    assert.same(
      { repo_root = '/x', base = 'main', head_sha = 'abc' },
      fm.parse { '---', 'repo_root: /x', "base: 'main'", 'head_sha: "abc"', '---', 'body: no' }
    )
    assert.same({}, fm.parse { '# no frontmatter' })
  end)
end)
