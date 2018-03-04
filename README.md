# Installation

## With Vundle
```
Plugin 'celforyon/vimmake'
```
then in vim `:VundleInstall`

## Manual installation
```
git clone https://github.com/celforyon/vimmake.git
cp vimmake/plugin/vimmake.vim ~/.vim/plugin
```
(optionally you can also install the docs and generate the tags with `:helptags`)

# Update

## Vundle
In vim `:VundleUpdate`

## Manual update
Simply redo manual installation steps

# Usage

## CMake

The command `:CMake` will touch all CMakeLists.txt files found in the project directory tree. You can use this command before running `:Make` or `:MakeAsync` if project files have been changed and you use globbing in your CMakeLists.txt, for example.

## Make

The command `:Make` will run the `make` shell command synchronously, displaying it in `vim` and into a log file (see `:MakeLog`)

You can bind it like
```
nnoremap <silent> <C-b> :Make<CR>
```

## MakeAsync

The command `:MakeAsync` will run the `make` shell command asynchronously, saving the output into a log file (see `MakeLog`)
To be available, you must have the *clientserver* feature enabled in vim, and launch vim with a server name (e.g. `vim --servername foo`)

To ease that, you can define an alias for `vim`:
```bash
alias vim='vim --servername $$'
```

You can bind it like
```
nnoremap <silent> <C-b> :MakeAsync<CR>
```

## MakeCustom

The command `:MakeCustom` will run a custom shell command, saving the output into a log file (see `MakeLog`)
To be available, you must define `g:vimmake_custom_make`.

## MakeLog

The command `:MakeLog` will open the last log file into the current buffer.

## ProjectRoot function

The function `ProjectRoot` can be used to get the project root directory as calculated by vimmake.

## ProjectMakefile function

The function `ProjectMakefile` can be used to get the project Makefile as calculated by vimmake.
