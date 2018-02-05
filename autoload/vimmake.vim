"""""""""""""""" Functions """"""""""""""""""""""""""""

function! vimmake#root(file)
	let dir = fnamemodify(a:file, ':h')
	if l:dir == ''
		return system('(git 2>/dev/null rev-parse --show-toplevel||pwd)|tr -d "\n"')
	endif
	return system('((cd '.l:dir.'; git 2>/dev/null rev-parse --show-toplevel)||pwd)|tr -d "\n"')
endfunction()

function! vimmake#sourceinfo(file)
	for srcdir in g:vimmake_srcdirs
		let cwd = getcwd()
		let updir = '.'
		while l:cwd =~ '/'.l:srcdir.'/' || l:cwd =~ '/'.l:srcdir.'$'
			let cwd = fnamemodify(l:cwd, ':h')
			let updir = l:updir.'/..'
		endwhile
		if a:file =~ '/'.l:srcdir.'/'
			let relfile = substitute(a:file, l:cwd.'/', './', '')
			let subdir = substitute(l:relfile, '/'.l:srcdir.'/.*', '', '')
			let subpath = simplify(fnamemodify(l:subdir, ':p').'/'.l:updir)
			return [1, l:subpath]
		endif
	endfor
	return [0, '']
endfunction()

function! vimmake#findmakefile(filesstr, subpath)
	let makefiles = split(a:filesstr, '\n')
	for makefile in l:makefiles
		if l:makefile =~ '^'.a:subpath
			return l:makefile
		endif
	endfor
	return l:makefiles[0]
endfunction()

function! vimmake#function()
	let cwd = getcwd()
	let file = expand('%:p')
	let srcinfo = vimmake#sourceinfo(l:file)
	let subpath = l:srcinfo[1]

	if !l:srcinfo[0]
		echohl VimMakeWarn|echo 'Cannot make: current buffer file is not in a source directory'|echohl None
		return
	endif

	let root = vimmake#root(l:file)
	let filesstr = globpath(l:root, '**/[Mm]akefile')

	if l:filesstr != ''
		let makefile = vimmake#findmakefile(l:filesstr, l:subpath)
		let makepath = fnamemodify(l:makefile, ':h')
		silent !clear

		cd `=l:subpath`
		silent execute 'make -C"'.l:makepath.'" '.g:vimmake_options
		redraw!
		botright cwindow
		cd `=l:cwd`
		echohl VimMakeDone|echo 'Compilation completed'|echohl None
	else
		echohl VimMakeWarn|echo 'Cannot make: no Makefile found'|echohl None
	endif
endfunction()
"""""""""""""""""""""""""""""""""""""""""""""""""""""""
