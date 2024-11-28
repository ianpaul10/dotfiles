" Enable line numbers and relative line numbers
set number
set relativenumber

" Enable 256 color support
set t_Co=256

" Set colorscheme
" colorscheme sorbet
colorscheme wildcharm

" Enable syntax highlighting
syntax enable

" Disable all bells/beeps
set belloff=all
set visualbell
set t_vb=

" Status line configuration
set laststatus=2  " Always show status line

" Basic status line with white text on dark grey
set statusline=%f\ %m%r%h%w%=%y[%{&ff}][%l,%v][%p%%]
hi StatusLine   ctermfg=darkgray ctermbg=white guibg=#FFFFFF guifg=#303030
hi StatusLineNC ctermfg=darkgray ctermbg=gray  guibg=#BBBBBB guifg=#303030
