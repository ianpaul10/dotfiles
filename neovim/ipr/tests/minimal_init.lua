local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
local plenary = vim.fn.stdpath 'data' .. '/lazy/plenary.nvim'

vim.opt.rtp:prepend(plenary)
vim.opt.rtp:prepend(plugin_root)
vim.opt.swapfile = false

vim.cmd 'runtime plugin/plenary.vim'
vim.cmd 'runtime plugin/ipr.lua'
