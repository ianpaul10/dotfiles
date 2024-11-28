" Enable line numbers and relative line numbers
set number
set relativenumber

" Status line configuration
set laststatus=2  " Always show status line

" Define colors for status line - themed for sorbet
hi Normal guibg=NONE ctermbg=NONE
hi StatusLine ctermfg=245 ctermbg=235 cterm=none
hi StatusLineNC ctermfg=245 ctermbg=none cterm=none
hi CursorLine cterm=none ctermbg=233 ctermfg=none

" Configure status line contents
set statusline=
set statusline+=%#StatusLine#                " Set color
set statusline+=\ %f\                        " File path relative to current directory
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

" Enable syntax highlighting
syntax enable

" Set a colorscheme (choose one that comes with vim by default)
" Some good options are:
" - desert
" - slate
" - murphy
" - pablo
colorscheme sorbet

" Enable true colors if your terminal supports it
if exists('+termguicolors')
  set termguicolors
endif
