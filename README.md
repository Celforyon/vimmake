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

## Make, MakeV

The commands `:Make` and `:MakeV` will run the `make` shell command synchronously, the first will log the output to a file (see `MakeLog`), the over will cat the output to vim.

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

## MakeLog

The command `:MakeLog` will open the last log file into the current buffer
