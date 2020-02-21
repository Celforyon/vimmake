"""""""""""""""" Variables """"""""""""""""""""""""""""

let s:tmp_file    = ''
let s:last_file   = ''
let s:cwd         = ''
let s:subpath     = ''
let s:pid         = ''
let s:scriptsdir  = fnamemodify(resolve(expand("<sfile>:p")), ':h:h').'/scripts/'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""" Functions """"""""""""""""""""""""""""

"""""""""""""""""""""""""""""""""""""""
"""" Utility """"""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""
function! vimmake#checkgitdir(dir)
	call system('cd '.a:dir.'; git>/dev/null 2>&1 rev-parse --show-toplevel')
	return !v:shell_error
endfunction

function! vimmake#root(file)
	let l:dir = fnamemodify(a:file, ':h')

	if vimmake#checkgitdir(l:dir)
		return system('cd '.l:dir.'; git 2>/dev/null rev-parse --show-toplevel|tr -d "\n"')
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
		return [0, '', '', '', '']
	endif

	let l:root = vimmake#root(l:file)
	let l:filesstr = globpath(l:root, '**/[Mm]akefile')

	if l:filesstr != ''
		let l:makefile = vimmake#findmakefile(l:filesstr, l:subpath)
		let l:makepath = fnamemodify(l:makefile, ':h')

		return [1, l:cwd, l:subpath, l:makepath, fnamemodify(l:makefile, ':t')]
	else
		echohl VimMakeWarn|echo 'Cannot make: no Makefile found'|echohl None
		return [0, '', '', '', '']
	endif
	return [0, '', '', '', '']
endfunction()

function! vimmake#makefile()
	let l:info = vimmake#getmakeinfo()
	let l:ok = info[0]
	let l:makepath = ''
	if l:ok
		let s:cwd = info[1]
		let s:subpath = info[2]
		let l:makepath = info[3].'/'.info[4]
	endif
	return l:makepath
endfunction

function! vimmake#function(fmake, bang, ...)
	let l:info = vimmake#getmakeinfo()
	let l:ok = info[0]
	if l:ok
		let s:cwd = info[1]
		let s:subpath = info[2]
		let l:makepath = info[3]

		call call(a:fmake, [l:makepath, a:bang, join(a:000, ' ')])
	endif
endfunction()

"""""""""""""""""""""""""""""""""""""""
"""" Make """""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""
function! vimmake#make(makepath, bang, options)
	" bang is ignored

	if g:vimmake_auto_custom_make && len(g:vimmake_custom_make)
		call vimmake#custom(a:options)
		return
	endif

	let s:tmp_file = tempname()
	let l:makecmd = &makeprg.' 2>&1'

	silent execute '!'.l:makecmd.' -C"'.a:makepath.'" '.g:vimmake_options.' '.a:options.'|tee '.s:tmp_file
	redraw!

	call vimmake#done(v:shell_error)
endfunction()

function! vimmake#async(makepath, bang, options)
	if exists('s:tmp_file')
		if s:tmp_file != ''
			if a:bang
				call vimmake#asynckill('-9')
			else
				" fix "hit enter to continue"
				let l:cmdheight = &cmdheight
				set cmdheight=2
				echohl VimMakeInfo|echo 'Make command already running ('.s:pid.')'|echohl None
				let &cmdheight = l:cmdheight
				return
			endif
		endif
	endif

	if len(v:servername) == 0
		echohl VimMakeWarn|echo 'requires a servername (:help --servername)'|echohl None
		return
	endif

	let s:tmp_file  = tempname()
	let l:cmd = s:scriptsdir.'maker
				\ '.shellescape(&makeprg).'
				\ '.shellescape(s:tmp_file).'
				\ '.shellescape(a:makepath).'
				\ '.shellescape(g:vimmake_options.' '.a:options).'
				\ '.shellescape(v:servername).'
				\ &'

	silent execute '!'.l:cmd
	redraw!

	echohl VimMakeInfo|echo "Launching compilation command..."|echohl None
endfunction()

function! vimmake#setpid(pid)
	let s:pid = a:pid
	echohl VimMakeInfo|echo '['.s:pid.'] Compilation in progress...'|echohl None
endfunction

function! vimmake#asynckill(sig)
	let l:sig = '-15'
	if a:sig != ''
		let l:sig = a:sig
	endif

	if s:pid == ''
		echohl VimMakeInfo|echo 'No async make command running'|echohl None
	else
		call system('kill '.l:sig.' '.s:pid)
	endif
endfunction

function! vimmake#custom(options)
	if len(g:vimmake_custom_make) == 0
		echohl VimMakeWarn|echo "you must define g:vimmake_custom_make"|echohl None
		return
	endif

	let s:tmp_file = tempname()
	let l:makecmd = g:vimmake_custom_make.' 2>&1'

	silent execute '!'.l:makecmd.' '.a:options.'|tee '.s:tmp_file
	redraw!

	let s:subpath = ''
	call vimmake#done(v:shell_error)
endfunction()

"""""""""""""""""""""""""""""""""""""""
"""" Post processing """"""""""""""""""
"""""""""""""""""""""""""""""""""""""""
function! vimmake#qfwindow(file)
	silent cgetfile `=a:file`
	botright cwindow
endfunction()

function! vimmake#done(shell_error)
	let s:pid = ''

	if len(s:subpath) != 0
		cd `=s:subpath`
	endif

	let l:view = winsaveview()
	call vimmake#qfwindow(s:tmp_file)
	call winrestview(l:view)
	cnext

	redraw!

	if len(s:subpath) != 0
		cd `=s:cwd`
		let s:subpath = ''
	endif

	let s:last_file = s:tmp_file
	unlet s:tmp_file

	if a:shell_error == 0
		echohl VimMakeDone|echo 'Compilation completed'|echohl None
	else
		echohl VimMakeWarn|echo 'Compilation failed ('.a:shell_error.')'|echohl None
	endif
endfunction()

"""""""""""""""""""""""""""""""""""""""
"""" Misc """""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""
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

"""""""""""""""""""""""""""""""""""""""
"""" Autocomplete functions """""""""""
"""""""""""""""""""""""""""""""""""""""
function! vimmake#autocomplete_kill(arglead, cmdline, cursorpos)
	let l:siglist = [
				\ '-KILL', '-TERM',
				\ '-SIGKILL', '-SIGTERM',
				\ '-9', '-15'
				\	]
	let l:completelist = []

	for sig in l:siglist
		if l:sig =~ '^'.a:arglead
			let l:completelist = l:completelist + [l:sig]
		endif
	endfor

	return l:completelist
endfunction

function! vimmake#autocomplete_make(arglead, cmdline, cursorpos)
	let l:makefile = vimmake#makefile()
	let l:rules = system('cat '.l:makefile.'|grep -E "^[^:. ][^: ]+:"|cut -d":" -f1')
	let l:rawrulelist = split(l:rules, '\n') + ['VERBOSE=1']
	let l:rulelist = []

	for rule in l:rawrulelist
		if l:rule =~ '^'.a:arglead
			let l:rulelist = l:rulelist + [l:rule]
		endif
	endfor

	return l:rulelist
endfunction
"""""""""""""""""""""""""""""""""""""""""""""""""""""""
