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
if !exists('g:vimmake_autocloseqf')
	let g:vimmake_autocloseqf = 0
endif
if !exists('g:vimmake_qfwrap')
	let g:vimmake_qfwrap = 1
endif
if !exists('g:vimmake_auto_custom_make')
	let g:vimmake_auto_custom_make = 1
endif
if !exists('g:vimmake_custom_make')
	let g:vimmake_custom_make = ''
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""" Highlights """""""""""""""""""""""""""

highlight VimMakeDoneDefault ctermfg=2
highlight VimMakeInfoDefault ctermfg=130

highlight link VimMakeDone VimMakeDoneDefault
highlight link VimMakeInfo VimMakeInfoDefault
highlight link VimMakeWarn WarningMsg

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""" Functions """"""""""""""""""""""""""""

function! ProjectRoot(...)
	let l:file = expand('%:p')
	if a:0 == 1
		let l:file = a:1
	endif
	return vimmake#root(simplify(l:file))
endfunction

function! ProjectMakefile()
	return vimmake#makefile()
endfunction

function! QuickFixWindow(file)
	return vimmake#qfwindow(a:file)
endfunction()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""" Commands """""""""""""""""""""""""""""

command! -nargs=* -complete=customlist,vimmake#autocomplete_make Make :call vimmake#function(function('vimmake#make'), <q-args>)
command! -nargs=* -complete=customlist,vimmake#autocomplete_make MakeAsync :call vimmake#function(function('vimmake#async'), <q-args>)
command! -nargs=* MakeCustom :call vimmake#custom(<q-args>)
command! MakeLog :call vimmake#log()
command! CMake :call vimmake#touchcmakelists()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
