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
"""""""""""""""" Functions """"""""""""""""""""""""""""
function! VimMakeRoot(file)
	let dir = fnamemodify(a:file, ':h')
	if l:dir == ''
		return system('(git 2>/dev/null rev-parse --show-toplevel||pwd)|tr -d "\n"')
	endif
	return system('((cd '.l:dir.'; git 2>/dev/null rev-parse --show-toplevel)||pwd)|tr -d "\n"')
endfunction()

function! VimMakeSourceInfo(file)
	for srcdir in g:vimmake_srcdirs
		if a:file =~ '/'.l:srcdir.'/'
			let relfile = substitute(a:file, getcwd().'/', './', '')
			let subdir = fnamemodify(l:relfile, '%:h')
			return [1, l:subdir, fnamemodify(l:subdir, ':p')]
		endif
	endfor
	return [0, '', '']
endfunction()

function! VimMakeFindMakefile(filesstr, subpath)
	let makefiles = split(a:filesstr, '\n')
	for makefile in l:makefiles
		if l:makefile =~ '^'.a:subpath
			return l:makefile
		endif
	endfor
	return l:makefiles[0]
endfunction()

function! VimMakeFunction()
	let cwd = getcwd()
	let file = expand('%:p')
	let srcinfo = VimMakeSourceInfo(l:file)
	let subdir = l:srcinfo[1]
	let subpath = l:srcinfo[2]

	if !l:srcinfo[0]
		echohl VimMakeWarn|echo 'Cannot make: current buffer file is not in a source directory'|echohl None
		return
	endif

	let root = VimMakeRoot(l:file)
	let filesstr = globpath(l:root, '**/[Mm]akefile')

	if l:filesstr != ''
		let makefile = VimMakeFindMakefile(l:filesstr, l:subpath)
		let makepath = fnamemodify(l:makefile, ':h')
		silent !clear

		if l:subdir != ''
			cd `=l:subdir`
		endif
		silent execute 'make -C"'.l:makepath.'" '.g:vimmake_options
		redraw!
		botright cwindow
		if l:subdir != ''
			cd `=l:cwd`
		endif
		echohl VimMakeDone|echo 'Compilation completed'|echohl None
	else
		echohl VimMakeWarn|echo 'Cannot make: no Makefile found'|echohl None
	endif
endfunction()
"""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""" Commands """""""""""""""""""""""""""""

command! Make :call VimMakeFunction()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
