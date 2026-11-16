local M = {}

function M.check()
  local health = vim.health
  local config = require 'ipr.config'
  local cfg = config.get()

  health.start 'ipr: required'
  if vim.fn.executable 'git' == 1 then
    health.ok('git: ' .. vim.trim(vim.fn.system { 'git', '--version' }))
  else
    health.error 'git not found on PATH'
  end

  health.start 'ipr: walkthrough'
  if vim.fn.executable(cfg.pi_cmd) == 1 then
    health.ok('pi: ' .. vim.fn.exepath(cfg.pi_cmd))
  else
    health.warn(cfg.pi_cmd .. ' not found; :iPR walkthrough will not work')
  end
  local _, skill_file = require('ipr.walkthrough').skill_paths()
  if vim.fn.filereadable(skill_file) == 1 then
    health.ok('skill: ' .. skill_file)
  else
    health.error('skill not found: ' .. skill_file)
  end
  local dir = config.reviews_dir()
  if vim.fn.isdirectory(dir) == 1 then
    health.ok('reviews_dir: ' .. dir)
  else
    health.info('reviews_dir will be created on first walkthrough: ' .. dir)
  end

  health.start 'ipr: base resolution (optional)'
  for _, bin in ipairs { 'dt', 'gh' } do
    if vim.fn.executable(bin) == 1 then
      health.ok(bin .. ' found')
    else
      health.info(bin .. ' not found (only needed for forge = "' .. bin .. '")')
    end
  end
  health.info('forge lookup: ' .. (cfg.forge or 'off'))

  local info = require('ipr.ctx').repo_info()
  if info then
    local resolved = require('ipr.base').resolve(info)
    if resolved then
      health.ok(string.format('current repo base: %s (via %s)', resolved.ref, resolved.source))
    else
      health.warn 'could not resolve a base for the current repo; use :iPR base <ref>'
    end
  end
end

return M
