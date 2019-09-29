# Schemer

Randomly generated color (neo)vim colorschemes.

![schemer-examples](https://user-images.githubusercontent.com/2793160/65826519-9c476180-e2c1-11e9-8889-124d90cdf329.gif)

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

## Limitations

Only works with Neovim, 'cause I didn't want to write the plugin in VimL or rely on an external scripting environment.

Currently only supports truecolor, so you'll need to run `set termguicolors` in order for the colors to show.

The way tokens are grouped does not vary. Only the colors. And not everything is colored, to maintain some sanity.

Assumes a black background. Apologies to light theme lovers.
