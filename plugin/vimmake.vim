" vimmake.vim
" Maintainer: Alexis Pereda
" Version: 1

if exists('g:loaded_vimmake')
	finish
endif
let g:loaded_vimmake = 1

"""""""""""""""" Variables """"""""""""""""""""""""""""

if !exists('g:vimmake_options')
	let g:vimmake_options = '-j4'
endif
if !exists('g:vimmake_srcdirs')
	let g:vimmake_srcdirs = ['src']
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""" Highlights """""""""""""""""""""""""""

highlight VimMakeDoneDefault ctermfg=2
highlight link VimMakeDone VimMakeDoneDefault
highlight link VimMakeWarn WarningMsg

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""" Commands """""""""""""""""""""""""""""

command! Make :call vimmake#function()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
