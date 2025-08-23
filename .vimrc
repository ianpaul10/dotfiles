" Enable line numbers and relative line numbers
set number
set relativenumber

" Change cursor shape in different modes
let &t_SI = "\e[6 q"  " Insert mode - vertical line
let &t_EI = "\e[2 q"  " Normal mode - block
set tm=10

" Enable 256 color support
set t_Co=256

" Enable syntax highlighting
syntax enable

" Disable all bells/beeps
set belloff=all
set visualbell
set t_vb=

" Status line configuration
set laststatus=2  " Always show status line

" column @ 120 chars in
" set colorcolumn=120

" Tab settings
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4

" Basic status line with white text on dark grey
set statusline=%f\ %m%r%h%w%=%y[%{&ff}][%l:%v][%p%%]
" Set status line colors after VimEnter
augroup StatusLineColors
  autocmd!
  autocmd ColorScheme * hi StatusLine ctermbg=15 ctermfg=237
  autocmd ColorScheme * hi StatusLineNC ctermbg=15 ctermfg=237
augroup END

" Set colorscheme
" colorscheme sorbet
colorscheme wildcharm

" clipboard support
if system('uname -s') == "Darwin\n"
  set clipboard=unnamed "OSX
else
  set clipboard=unnamedplus "Linux
endif
