local git = require 'ipr.git'

describe('git.run', function()
  it('returns a result instead of throwing for a missing binary', function()
    local res = git.run { 'definitely-not-a-real-binary-ipr' }
    assert.is_false(res.ok)
  end)

  it('captures stdout', function()
    local res = git.run { 'echo', 'hi' }
    assert.is_true(res.ok)
    assert.equals('hi\n', res.stdout)
  end)
end)

describe('git.parse_name_status', function()
  it('parses -z output including renames', function()
    local text = table.concat({ 'M', 'src/a.ts', 'A', 'src/new file.ts', 'R087', 'old.ts', 'new.ts', 'D', 'gone.ts', '' }, '\0')
    assert.same({
      { status = 'M', path = 'src/a.ts' },
      { status = 'A', path = 'src/new file.ts' },
      { status = 'R', old_path = 'old.ts', path = 'new.ts' },
      { status = 'D', path = 'gone.ts' },
    }, git.parse_name_status(text))
  end)
end)

describe('git.parse_hunks', function()
  local diff = table.concat({
    'diff --git a/src/a.ts b/src/a.ts',
    'index 111..222 100644',
    '--- a/src/a.ts',
    '+++ b/src/a.ts',
    '@@ -3 +3 @@ function foo',
    '-old',
    '+new',
    '@@ -10,0 +11,4 @@',
    '+a',
    'diff --git a/gone.ts b/gone.ts',
    'deleted file mode 100644',
    '--- a/gone.ts',
    '+++ /dev/null',
    '@@ -1,40 +0,0 @@',
    'diff --git a/bin.png b/bin.png',
    'Binary files a/bin.png and b/bin.png differ',
    '',
  }, '\n')

  it('groups hunks by path and defaults missing counts to 1', function()
    local hunks = git.parse_hunks(diff)
    assert.same({
      { old_start = 3, old_count = 1, new_start = 3, new_count = 1 },
      { old_start = 10, old_count = 0, new_start = 11, new_count = 4 },
    }, hunks['src/a.ts'])
  end)

  it('keys deleted files by their old path', function()
    assert.same({ { old_start = 1, old_count = 40, new_start = 0, new_count = 0 } }, git.parse_hunks(diff)['gone.ts'])
  end)

  it('ignores binary files', function()
    assert.is_nil(git.parse_hunks(diff)['bin.png'])
  end)
end)

describe('git.summarize', function()
  it('splits hunks into added, removed and changed', function()
    local hunks = {
      { old_start = 1, old_count = 3, new_start = 1, new_count = 7 },
      { old_start = 20, old_count = 5, new_start = 24, new_count = 2 },
      { old_start = 40, old_count = 0, new_start = 41, new_count = 1 },
    }
    assert.same({ added = 5, removed = 3, changed = 5 }, git.summarize(hunks))
  end)

  it('handles no hunks', function()
    assert.same({ added = 0, removed = 0, changed = 0 }, git.summarize(nil))
  end)
end)

describe('git.first_line', function()
  it('uses new_start, old_start for deletions, and clamps to 1', function()
    local hunks = { { old_start = 5, old_count = 1, new_start = 0, new_count = 0 } }
    assert.equals(1, git.first_line(hunks, false))
    assert.equals(5, git.first_line(hunks, true))
    assert.equals(1, git.first_line({}, false))
  end)
end)
