" Enable line numbers and relative line numbers
set number
set relativenumber

" Enable 256 color support
set t_Co=256

" Set colorscheme
colorscheme wildcharm

" Enable syntax highlighting
syntax enable

" Status line configuration
set laststatus=2  " Always show status line

" Basic status line with white text on dark grey
set statusline=%f\ %m%r%h%w%=%y[%{&ff}][%l,%v][%p%%]
hi StatusLine   ctermfg=white ctermbg=darkgray guifg=#FFFFFF guibg=#303030
hi StatusLineNC ctermfg=gray  ctermbg=darkgray guifg=#BBBBBB guibg=#303030


