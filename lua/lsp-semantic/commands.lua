local lspSemantic = require'lsp-semantic'

local M = {}

M.cmd_dump_symbols = function()
    local ret = lspSemantic.dump_symbols()
    if ret then
        print(vim.inspect(ret))
    end
end

M.cmd_dump_cursor = function()
    local ret = lspSemantic.dump_cursor()
    if ret then print(vim.inspect(ret))
    else
        print("No valid symbol was found!")
    end
end

M.cmd_enable = function()
    lspSemantic.enable_buffer(0)
    print("LspSemantic was enabled!")
end

M.cmd_disable = function()
    lspSemantic.disable_buffer(0)
    print("LspSemantic was disabled!")
end

return M
