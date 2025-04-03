-- [[ Basic Keymaps ]]

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix' })
vim.diagnostic.config { virtual_text = false }

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
-- smart vertical window split
vim.keymap.set('n', '<C-w><C-v>', '<C-w>v<C-w><C-h><C-6><C-w><C-l>', { desc = 'Smart vertical window split' })

-- [[ Shortcuts for switching between buffers ]]
vim.keymap.set('n', 'g0', ':bnext<CR>', { desc = '[G]o to the next buffer (i.e. file)' })
vim.keymap.set('n', 'g9', ':bprevious<CR>', { desc = '[G]o to the previous buffer (i.e. file)' })
vim.keymap.set('n', 'gq', ':bdelete<CR>', { desc = '[q]uit the current buffer (i.e. file)' })
vim.keymap.set('n', 'gw', ':bp | bd #<CR>', { desc = '[q]uit the current buffer (i.e. file) without closing the buffer window' })
vim.keymap.set('n', 'gQ', ':bdelete!<CR>', { desc = 'Force [Q]uit the current buffer (i.e. file)' })

-- Remove keymap of s for vim in favour of mini.nvim mini.surround
-- Acltually not remvoing for now. Not worrying about mini.surround ATM
-- vim.keymap.set('n', 's', '<Nop>', { desc = 'Ignore default [s] keymap in favour of mini.nvim mini.surround' })

-- When highlighted, you can move text around the buffer
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv'", { desc = 'Move highlighted text up or down' })
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv'", { desc = 'Move highlighted text up or down' })

-- For jumping up and down the file, keep cursor in middle of the screen
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Keep cursor in middle when jumping up/down' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Keep cursor in middle when jumping up/down' })

-- When filtering through searched words in the doc, always keep searched term in middle of screen
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- netrw, :Ex, :Explore, :Lexplore commands
vim.keymap.set('n', '\\', ':Lexplore <CR>', { desc = 'Toggle netrw / Explore window' })
vim.keymap.set('n', '|', ':Lexplore %:p:h <CR>', { desc = 'Toggle netrw / Explore window in current file directory' })

-- Close all buffers except for currently opened one
--
-- - `:%bd`: Deletes all buffers.
-- - `:e#`: Opens the most recent buffer, which is the one you want to keep.
vim.keymap.set('n', '<leader>wd', ':%bd | :e# <CR>', { desc = '[D]elete all buffers except currently opened one' })

-- Copy the current line, paste it, and comment the first instance of it out
vim.keymap.set('n', '<leader>cc', 'yypkI# <Esc>j', { desc = '[C]opy current line, paste it, and comment the first instance of it out' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- NOTE: notes
vim.keymap.set('n', '<leader>bd', ':e ~/code/brain_dump/notes.md <CR>', { desc = 'Brain dump' })
