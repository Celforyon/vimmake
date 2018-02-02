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

By default, `:Make` of `call VimMakeFunction`

You can bind it like
```
nnoremap <silent> <C-b> :Make<CR>
```
