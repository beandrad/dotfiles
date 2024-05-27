set nocompatible
set backspace=2
 
au BufWrite /private/tmp/crontab.* set nowritebackup nobackup
 
au BufWrite /private/etc/pw.* set nowritebackup nobackup
 
highlight ColorColumn ctermbg=238
 
au FileType gitcommit setlocal tw=72
au FileType gitcommit setlocal cc=+1
au FileType gitcommit set cc+=51
set complete+=kspell
au FileType gitcommit setlocal spell
