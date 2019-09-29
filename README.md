# Schemer

## Installation

### With Vim-Plug

```viml
Plug 'Resonious/nvim-schemer'
```

### With Pathogen

```bash
$ git clone https://github.com/Resonious/nvim-schemer ~/.config/nvim/bundle/nvim-schemer
```

## Usage

Adds `:Schemer` command to generate random colors.

Run `:SchemerSave "mythemename"` to save your currently generated scheme.

To generate a new scheme for every vim session, stick `autocmd VimEnter * Schemer` into your `init.vim`.

**NOTE** nvim-schemer currently only supports truecolor, so you'll need to run `set termguicolors` in order for the colors to show.
