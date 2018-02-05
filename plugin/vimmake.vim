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
if !exists('g:vimmake_vim')
	let g:vimmake_vim = 'vim'
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""" Highlights """""""""""""""""""""""""""

highlight VimMakeDoneDefault ctermfg=2
highlight VimMakeInfoDefault ctermfg=130

highlight link VimMakeDone VimMakeDoneDefault
highlight link VimMakeInfo VimMakeInfoDefault
highlight link VimMakeWarn WarningMsg

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""" Commands """""""""""""""""""""""""""""

command! Make :call vimmake#function(function('vimmake#make'))
command! MakeV :call vimmake#function(function('vimmake#makev'))
command! MakeAsync :call vimmake#function(function('vimmake#async'))
command! MakeLog :call vimmake#openlast()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
