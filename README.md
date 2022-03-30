# lsp-semantic
Semantic Tokens support for NeoVim's builtin LSP

## Introduction
The 3.16 version of the Language Server Protocol added support for [Semantic Tokens](https://microsoft.github.io/language-server-protocol/specification). You can use them to get semantic highlight using the LSP on your text editor, but currently there's no native support in NeoVim for Semantic Tokens, so I've created this plugin to get semantic highlight to work on NeoVim.

![image](https://user-images.githubusercontent.com/19158283/160946727-c0b0c14e-109b-4e8f-8baf-9ea60863cbbc.png)

## Setup
Add this function to your LSP configuration:

```lua
require'lspconfig'.clangd.setup {
    before_init = require'lsp-semantic'.before_init,
}
```

## Time between updates
Currently, this plugin is using ```CursorHold``` event to update the buffer, if you want to decrease the time between updates, you must decrease the ```updatetime``` (see ```:h CursorHold``` and ```:h updatetime```).
```vim
set updatetime=300
```

## Notes
This plugin is not complete, if you find any bug feel free to submit an issue.
