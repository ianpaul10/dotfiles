return {
  'nvim-lua/plenary.nvim',
  config = function()
    local function observe_log_query()
      local file = vim.fn.expand '%:p'
      local line = vim.fn.line '.'
      local cmd = 'bin/observe-log-query ' .. file .. ':' .. line

      local output = vim.fn.system(cmd)

      -- Extract first URL from output
      local url = output:match 'https://[^\n]+'

      if url then
        -- Open in browser (macOS)
        vim.fn.system('open ' .. vim.fn.shellescape(url))
        vim.notify('Opened Observe query in browser', vim.log.levels.INFO)
      else
        vim.notify('No URL found in output:\n' .. output, vim.log.levels.ERROR)
      end
    end

    vim.keymap.set('n', '<leader>oq', observe_log_query, {
      noremap = true,
      silent = true,
      desc = '[O]bserve log [Q]uery',
    })
  end,
}
