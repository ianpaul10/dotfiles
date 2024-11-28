" Enable line numbers and relative line numbers
set number
set relativenumber

" Set a colorscheme (choose one that comes with vim by default)
" Some good options are:
" - desert
" - slate
" - murphy
" - pablo
" - wildcharm
" - sorbet
colorscheme wildcharm

" Status line configuration
set laststatus=2  " Always show status line

" Configure status line contents
set statusline=\ %f\                        " File path relative to current directory
set statusline+=%m                           " Modified flag [+]
set statusline+=%r                           " Readonly flag [RO]
set statusline+=%h                           " Help buffer flag [Help]
set statusline+=%w                           " Preview window flag [Preview]
set statusline+=%=                           " Switch to right side
set statusline+=%y\                          " File type [vim]
set statusline+=[%{&fileencoding?&fileencoding:&encoding}] " File encoding
set statusline+=[%{&fileformat}]\            " File format (unix/dos)
set statusline+=\ %l:%c\                     " Line:Column
set statusline+=%p%%\                        " Percentage through file

" Custom highlights for status line
autocmd ColorScheme * highlight StatusLine      ctermfg=white  ctermbg=black  guifg=#444444 guibg=#2E2E2E
autocmd ColorScheme * highlight StatusLineNC    ctermfg=gray      ctermbg=black  guifg=#606060 guibg=#2E2E2E
highlight PmenuSel        ctermfg=black     ctermbg=cyan   guifg=#2E2E2E guibg=#87AFD7
highlight LineNr          ctermfg=cyan      ctermbg=black   guifg=#87AFD7 guibg=#2E2E2E
highlight Visual          ctermfg=darkgray  ctermbg=magenta guifg=#444444 guibg=#D70087
highlight WildMenu        ctermfg=darkgray  ctermbg=blue   guifg=#444444 guibg=#005F87
highlight TabLineFill     ctermfg=gray      ctermbg=black  guifg=#606060 guibg=#2E2E2E

" Enable syntax highlighting
syntax enable

" Enable true colors if your terminal supports it
if exists('+termguicolors')
  set termguicolors
endif
