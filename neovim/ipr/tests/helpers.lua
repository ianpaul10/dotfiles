local H = {}

local function sh(cwd, cmd)
  local res = vim.system(cmd, { cwd = cwd, text = true }):wait()
  if res.code ~= 0 then
    error(table.concat(cmd, ' ') .. ' failed: ' .. (res.stderr or ''))
  end
  return vim.trim(res.stdout or '')
end

---Run git in a fixture repo, isolated from global hooks and signing.
function H.git(dir, ...)
  local cmd = { 'git', '-c', 'core.hooksPath=/dev/null', '-c', 'commit.gpgsign=false', '-c', 'user.name=t', '-c', 'user.email=t@t' }
  vim.list_extend(cmd, { ... })
  return sh(dir, cmd)
end

function H.repo()
  local dir = vim.fs.normalize(vim.fn.resolve(vim.fn.tempname()))
  vim.fn.mkdir(dir, 'p')
  H.git(dir, 'init', '-q', '-b', 'main')
  H.write(dir, 'README.md', 'hello\n')
  H.commit(dir, 'init')
  return dir
end

function H.write(dir, rel, content)
  local path = dir .. '/' .. rel
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  local f = assert(io.open(path, 'w'))
  f:write(content)
  f:close()
end

function H.commit(dir, msg)
  H.git(dir, 'add', '-A')
  H.git(dir, 'commit', '-q', '--no-verify', '-m', msg)
end

function H.lines(n, prefix)
  local out = {}
  for i = 1, n do
    out[i] = (prefix or 'line') .. ' ' .. i
  end
  return table.concat(out, '\n') .. '\n'
end

return H
