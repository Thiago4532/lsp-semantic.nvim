local lspSemantic = require'lsp-semantic'

local function cmd_dump_symbols()
    local ret = lspSemantic.dump_symbols()
    if ret then
        print(vim.inspect(ret))
    end
end

local function cmd_dump_cursor()
    local ret = lspSemantic.dump_cursor()
    if ret then print(vim.inspect(ret))
    else
        print("No valid symbol was found!")
    end
end

return {
    cmd_dump_symbols = cmd_dump_symbols,
    cmd_dump_cursor = cmd_dump_cursor
}
