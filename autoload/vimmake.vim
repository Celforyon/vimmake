"""""""""""""""" Variables """"""""""""""""""""""""""""

let s:tmp_file = ''
let s:last_file = ''
let s:cwd = ''
let s:subpath = ''

let s:vimcmd  = 'vim --servername "'.v:servername.'" --remote-expr "vimmake\#done()"'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""" Functions """"""""""""""""""""""""""""

function! vimmake#checkgitdir(dir)
	call system('(cd '.a:dir.'; git>/dev/null 2>&1 rev-parse --show-toplevel)')
	return !v:shell_error
endfunction

function! vimmake#root(file)
	let l:dir = fnamemodify(a:file, ':h')

	if vimmake#checkgitdir(l:dir)
		return system('(cd '.l:dir.'; git 2>/dev/null rev-parse --show-toplevel)|tr -d "\n"')
	else
		for srcdir in g:vimmake_srcdirs
			while l:dir =~ '/'.l:srcdir.'/' || l:dir =~ '/'.l:srcdir.'$'
				let l:dir = fnamemodify(l:dir, ':h')
			endwhile
		endfor
	endif

	return l:dir
endfunction()

function! vimmake#sourceinfo(file)
	for srcdir in g:vimmake_srcdirs
		let l:cwd = getcwd()
		let l:updir = '.'
		while l:cwd =~ '/'.l:srcdir.'/' || l:cwd =~ '/'.l:srcdir.'$'
			let l:cwd = fnamemodify(l:cwd, ':h')
			let l:updir = l:updir.'/..'
		endwhile
		if a:file =~ '/'.l:srcdir.'/'
			let l:relfile = substitute(a:file, l:cwd.'/', './', '')
			let l:subdir = substitute(l:relfile, '/'.l:srcdir.'/.*', '', '')
			let l:subpath = simplify(fnamemodify(l:subdir, ':p').'/'.l:updir)
			return [1, l:subpath]
		endif
	endfor
	return [0, '']
endfunction()

function! vimmake#findmakefile(filesstr, subpath)
	let l:makefiles = split(a:filesstr, '\n')
	for makefile in l:makefiles
		if l:makefile =~ '^'.a:subpath
			return l:makefile
		endif
	endfor
	return l:makefiles[0]
endfunction()

function! vimmake#getmakeinfo()
	let l:cwd = getcwd()
	let l:file = expand('%:p')
	let l:srcinfo = vimmake#sourceinfo(l:file)
	let l:subpath = l:srcinfo[1]

	if !l:srcinfo[0]
		echohl VimMakeWarn|echo 'Cannot make: current buffer file is not in a source directory'|echohl None
		return [0, '', '', '']
	endif

	let l:root = vimmake#root(l:file)
	let l:filesstr = globpath(l:root, '**/[Mm]akefile')

	if l:filesstr != ''
		let l:makefile = vimmake#findmakefile(l:filesstr, l:subpath)
		let l:makepath = fnamemodify(l:makefile, ':h')

		return [1, l:cwd, l:subpath, l:makepath]
	else
		echohl VimMakeWarn|echo 'Cannot make: no Makefile found'|echohl None
		return [0, '', '', '']
	endif
	return [0, '', '', '']
endfunction()

function! vimmake#function(fmake)
	if exists('s:tmp_file')
		if s:tmp_file != ''
			echohl VimMakeInfo|echo 'Make is already running...'|echohl None
			return
		endif
	endif

	let l:info = vimmake#getmakeinfo()
	let l:ok = info[0]
	if l:ok
		let s:cwd = info[1]
		let s:subpath = info[2]
		let l:makepath = info[3]

		call call(a:fmake, [l:makepath])
	endif
endfunction()

function! vimmake#make(makepath)
		let s:tmp_file = tempname()
		let l:makecmd = &makeprg.' 2>&1'

		silent execute '!'.l:makecmd.' -C"'.a:makepath.'" '.g:vimmake_options.'|tee '.s:tmp_file
		redraw!

		call vimmake#done()
endfunction()

function! vimmake#async(makepath)
	if len(v:servername) == 0
		echohl VimMakeWarn|echo "requires a servername (:help --servername)"|echohl None
		return
	endif

	let s:tmp_file = tempname()
	let l:makecmd = &makeprg.'>'.s:tmp_file.' 2>&1'

	silent execute '!('.l:makecmd.' -C"'.a:makepath.'" '.g:vimmake_options.'; '.s:vimcmd.'>/dev/null)&'
	redraw!

	echohl VimMakeInfo|echo 'Compilation in progress...'|echohl None
endfunction()

function! vimmake#done()
	cd `=s:subpath`
	silent cfile `=s:tmp_file`
	botright cwindow
	cd `=s:cwd`
	let s:last_file = s:tmp_file
	unlet s:tmp_file

	echohl VimMakeDone|echo 'Compilation completed'|echohl None
endfunction()

function! vimmake#log()
	if s:last_file != ''
		pedit `=s:last_file`
		wincmd P
		setlocal buftype=nofile bufhidden=hide noswapfile
	else
		echohl VimMakeInfo|echo "no last make log"|echohl None
	endif
endfunction()

function! vimmake#touchcmakelists()
	let l:root = vimmake#root(expand('%:p'))
	let l:cmakelistsfilesstr = globpath(l:root, '**/CMakeLists.txt')
	let l:cmakelistsfiles = split(l:cmakelistsfilesstr, '\n')

	if l:cmakelistsfilesstr != ''
		for cmakelistsfile in l:cmakelistsfiles
			silent execute ':!touch '.l:cmakelistsfile
		endfor
		redraw!
		echohl VimMakeDone|echo 'CMakeLists.txt touched'|echohl None
	else
		echohl VimMakeWarn|echo 'No CMakeLists.txt'|echohl None
		return
	endif
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""""
