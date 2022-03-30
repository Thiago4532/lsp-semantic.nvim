# lsp-semantic
Semantic Tokens support for NeoVim's builtin LSP

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
