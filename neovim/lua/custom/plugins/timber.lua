M = {
  'Goose97/timber.nvim',
  version = '*', -- Use for stability; omit to use `main` branch for the latest features
  event = 'VeryLazy',
  config = function()
    require('timber').setup {
      -- Configuration here, or leave empty to use defaults
      log_watcher = {
        enabled = true,
        -- A table of source id and source configuration
        sources = {
          log_file = {
            type = 'filesystem',
            name = 'Log file',
            path = '/tmp/debug.log',
          },
        },
      },
    }
  end,
}

return M
