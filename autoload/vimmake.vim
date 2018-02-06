"""""""""""""""" Variables """"""""""""""""""""""""""""

let s:tmp_file = ''
let s:last_file = ''
let s:cwd = ''
let s:subpath = ''

let s:vimcmd  = 'vim --servername "'.v:servername.'" --remote-expr "vimmake\#done()"'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
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

function! vimmake#getmakeinfo()
	let cwd = getcwd()
	let file = expand('%:p')
	let srcinfo = vimmake#sourceinfo(l:file)
	let subpath = l:srcinfo[1]

	if !l:srcinfo[0]
		echohl VimMakeWarn|echo 'Cannot make: current buffer file is not in a source directory'|echohl None
		return [0, '', '', '']
	endif

	let root = vimmake#root(l:file)
	let filesstr = globpath(l:root, '**/[Mm]akefile')

	if l:filesstr != ''
		let makefile = vimmake#findmakefile(l:filesstr, l:subpath)
		let makepath = fnamemodify(l:makefile, ':h')

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

	let info = vimmake#getmakeinfo()
	let ok = info[0]
	if l:ok
		let s:cwd = info[1]
		let s:subpath = info[2]
		let makepath = info[3]

		call call(a:fmake, [l:makepath])
	endif
endfunction()

function! vimmake#make(makepath)
		let s:tmp_file = tempname()
		let makecmd = &makeprg.' 2>&1'

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
	let makecmd = &makeprg.'>'.s:tmp_file.' 2>&1'

	silent execute '!('.l:makecmd.' -C"'.a:makepath.'" '.g:vimmake_options.'; '.s:vimcmd.'>/dev/null)&'
	redraw!

	echohl VimMakeDone|echo 'Compilation in progress...'|echohl None
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

function! vimmake#openlast()
	if s:last_file != ''
		edit `=s:last_file`
	else
		echohl VimMakeInfo|echo "no last make log"|echohl None
	endif
endfunction()
"""""""""""""""""""""""""""""""""""""""""""""""""""""""
