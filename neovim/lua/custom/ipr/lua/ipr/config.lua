local M = {}

M.defaults = {
  reviews_dir = '~/code/scratch/pi/reviews',
  -- nil uses the bundled skills/ipr-walkthrough skill
  skill = nil,
  pi_cmd = 'pi',
  pi_args = { '-p', '--no-session' },
  open_on_complete = false,
  -- nil | 'dt' | 'gh': opt-in network lookup of the PR's base branch
  forge = nil,
  -- set any key to false to disable it
  keys = {
    files = '<leader>ipf',
    files_all = '<leader>ipF',
    walkthrough = '<leader>ipw',
    open = '<leader>ipo',
    base = '<leader>ipb',
    links = '<leader>ipl',
    jump = { '<CR>', 'gd' },
    next_link = ']l',
    prev_link = '[l',
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend('force', vim.deepcopy(M.defaults), opts)
  -- lists should replace, not merge index-by-index
  if opts.keys and opts.keys.jump ~= nil then
    M.options.keys.jump = opts.keys.jump
  end
  if opts.pi_args ~= nil then
    M.options.pi_args = opts.pi_args
  end
  return M.options
end

function M.get()
  return M.options
end

function M.reviews_dir()
  return vim.fs.normalize(vim.fn.expand(M.options.reviews_dir))
end

return M
