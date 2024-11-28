" Enable line numbers and relative line numbers
set number
set relativenumber

" Enable status line and configure it
set laststatus=2
set statusline=%f\ %h%w%m%r\ %=%(%l,%c%V\ %=\ %P%)

" Enable syntax highlighting
syntax enable

" Set a colorscheme (choose one that comes with vim by default)
" Some good options are:
" - desert
" - slate
" - murphy
" - pablo
colorscheme desert

" Enable true colors if your terminal supports it
if exists('+termguicolors')
  set termguicolors
endif
