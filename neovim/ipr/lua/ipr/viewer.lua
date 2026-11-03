local config = require 'ipr.config'
local frontmatter = require 'ipr.frontmatter'

local M = {}

local function slug(s)
  return require('ipr.walkthrough').slug(s)
end

local function mtime(path)
  local stat = vim.uv.fs_stat(path)
  return stat and (stat.mtime.sec * 1e9 + stat.mtime.nsec) or 0
end

---Reviews for this repo + branch, newest first.
---@param ctx IprCtx
---@return string[]
function M.find(ctx)
  local repo, branch = slug(ctx.repo), slug(ctx.branch or 'detached')
  local exact = '^%d+_%d+_%d+_' .. vim.pesc(repo) .. '_' .. vim.pesc(branch) .. '_%x+%.md$'
  local candidates = vim.fn.glob(config.reviews_dir() .. '/*_' .. repo .. '_' .. branch .. '_*.md', false, true)
  local matches = vim.tbl_filter(function(path)
    return vim.fs.basename(path):match(exact) ~= nil
  end, candidates)
  table.sort(matches, function(a, b)
    return mtime(a) > mtime(b)
  end)
  return matches
end

---@param bufnr integer
---@param ctx? IprCtx
local function warn_if_stale(bufnr, ctx)
  local head_sha = frontmatter.read_buf(bufnr).head_sha
  if not (ctx and head_sha) or vim.b[bufnr].ipr_stale_warned then
    return
  end
  if not vim.startswith(ctx.head_sha, head_sha) and not vim.startswith(head_sha, ctx.head_sha) then
    vim.b[bufnr].ipr_stale_warned = true
    require('ipr').notify(
      string.format('review was written for %s, HEAD is now %s; line numbers may be stale', head_sha:sub(1, 10), ctx.head_sha:sub(1, 10)),
      vim.log.levels.WARN
    )
  end
end

---Open a review in a right-hand 50% split, remembering the window we came from.
---@param path string
---@param ctx? IprCtx
function M.open(path, ctx)
  local source_win = vim.api.nvim_get_current_win()
  local existing = vim.fn.bufwinid(vim.fn.bufnr(path))
  if existing ~= -1 then
    vim.api.nvim_set_current_win(existing)
  else
    vim.cmd('botright vsplit ' .. vim.fn.fnameescape(path))
    vim.api.nvim_win_set_width(0, math.floor(vim.o.columns / 2))
    vim.b.ipr_source_win = source_win
  end
  require('ipr.links').attach(vim.api.nvim_get_current_buf())
  warn_if_stale(vim.api.nvim_get_current_buf(), ctx)
end

---:iPR open [path]
function M.open_command(args)
  local ctx = require('ipr.commands').ctx()
  if not ctx then
    return
  end
  local path = args[1] and vim.fn.expand(args[1]) or M.find(ctx)[1]
  if not path then
    return require('ipr').notify('no review for ' .. (ctx.branch or 'HEAD') .. ' yet; run :iPR walkthrough', vim.log.levels.WARN)
  end
  M.open(path, ctx)
end

return M
