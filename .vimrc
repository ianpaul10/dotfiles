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

" Enable syntax highlighting
syntax enable

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


