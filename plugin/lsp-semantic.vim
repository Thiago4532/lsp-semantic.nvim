if exists('g:loaded_lsp_semantic')
    finish
endif
let g:loaded_lsp_semantic = 1

"" Commands
command LspSemanticDumpSymbols lua require'lsp-semantic/commands'.cmd_dump_symbols()
command LspSemanticDumpCursor lua require'lsp-semantic/commands'.cmd_dump_cursor()

"" Syntax Highlight

" Type
highlight default link LspSemanticType Type
highlight default link LspSemanticClass Type
highlight default link LspSemanticEnum Type
highlight default link LspSemanticStruct Type
highlight default link LspSemanticTypeParameter Type

" Function
highlight default link LspSemanticFunction Function
highlight default link LspSemanticMethod LspSemanticFunction

" Enum constant
highlight default link LspSemanticEnumMember Constant

highlight default link LspSemanticVariable Normal
highlight default link LspSemanticProperty LspSemanticVariable
highlight default link LspSemanticParameter LspSemanticVariable

" Macro
highlight default link LspSemanticMacro Macro

" Comment
highlight default link LspSemanticComment Comment

" Namespace 
highlight default link LspSemanticNamespace Include
