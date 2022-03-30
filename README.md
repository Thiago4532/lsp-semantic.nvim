# lsp-semantic
Semantic Tokens support for NeoVim's builtin LSP.

## Setup
Add this function to your LSP configuration:

```lua
require'lspconfig'.clangd.setup {
    before_init = require'lsp-semantic'.before_init,
}
```
