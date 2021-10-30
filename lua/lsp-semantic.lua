local vim = vim
local api, lsp = vim.api, vim.lsp
local util, protocol = lsp.util, lsp.protocol
local bit = bit

local function err_message(...)
    vim.notify(table.concat(vim.tbl_flatten{...}), vim.log.levels.ERROR)
    api.nvim_command("redraw")
end

local function modify_capabilities(capabilities)
    capabilities['textDocument'].semanticTokens = {
        requests = {
            range = false,
            full = {
                delta = true
            }
        },
        multilineTokenSupport = false
    }
end

-- TODO: Support more than 23 modifiers
local function modifiers_to_bit_table(modifiers)
    local tbl, key = {}, 1
    for _,mod in ipairs(modifiers) do
        tbl[key] = mod
        key = key * 2
    end

    return tbl
end

local function modify_resolved_capabilities(server_capabilities, tbl)
    local smp = server_capabilities.semanticTokensProvider
    if smp then
        tbl['semantic_tokens'] = {
            full = not not smp.full,
            full_delta = smp.full and smp.full.delta,
            range = not not smp.range,
        }
        tbl['semantic_tokens_types'] = smp.legend and smp.legend.tokenTypes or {}
        tbl['semantic_tokens_modifiers'] = modifiers_to_bit_table(smp.legend and smp.legend.tokenModifiers or {})
    else
        tbl['semantic_tokens'] = {
            full = false,
            full_delta = false,
            range = false,
        }
        tbl['semantic_tokens_types'] = {}
        tbl['semantic_tokens_modifiers'] = {}
    end
end

local function parse_modifiers(m, modifiers_tbl)
    local tbl = {}
    while m ~= 0 do
        local lsb = bit.band(m, -m)
        tbl[#tbl + 1] = modifiers_tbl[lsb]

        m = m - lsb  
    end

    return tbl
end

local function parse_data(data, types, modifiers_tbl)
    local line = 0
    local start = 0
    local length = 0
    local type = ""
    local modifiers = {}

    local tbl = {}
    for i=1,#data,5 do
        line = data[i] + line
        start = data[i+1] + (data[i] == 0 and start or 0)
        length = data[i+2]
        type = types[data[i+3] + 1]
        modifiers = parse_modifiers(data[i+4], modifiers_tbl)

        tbl[#tbl + 1] = {
            line = line,
            start = start,
            length = length,
            type = type,
            modifiers = modifiers,
        }
    end
    return tbl
end

local previous_result_buffer = {}

local types_highlight = {
    ["namespace"] = "LspSemanticNamespace",
    ["type"] = "LspSemanticType",
    ["class"] = "LspSemanticClass",
    ["enum"] = "LspSemanticEnum",
    ["struct"] = "LspSemanticStruct",
    ["typeParameter"] = "LspSemanticTypeParameter",
    ["parameter"] = "LspSemanticParameter",
    ["variable"] = "LspSemanticVariable",
    ["property"] = "LspSemanticProperty",
    ["enumMember"] = "LspSemanticEnumMember",
    ["function"] = "LspSemanticFunction",
    ["method"] = "LspSemanticMethod",
    ["macro"] = "LspSemanticMacro",
    ["comment"] = "LspSemanticComment",
}

local function lsp_handler_full(_, result, ctx, _)
    local client_id = ctx.client_id
    local client = lsp.get_client_by_id(client_id)
    local bufnr = ctx.bufnr
    if not client or not result or not result.data then 
        return
    end
    previous_result_buffer[bufnr] = result
    previous_result_buffer[bufnr].clientId = client_id

    local custom_types = client.config.semantic_highlight
                         and client.config.semantic_highlight.custom_types
                         or {}

    local data = result.data
    local types = client.resolved_capabilities.semantic_tokens_types
    local modifiers = client.resolved_capabilities.semantic_tokens_modifiers

    local symbols = parse_data(data, types, modifiers)
    local ns = api.nvim_create_namespace("lsp-semantic-namespace")
    api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    for _,symbol in ipairs(symbols) do
        local line = symbol.line
        local col_start = symbol.start
        local col_end = col_start + symbol.length
        local hl = custom_types[symbol.type] or types_highlight[symbol.type]

        if hl then
            api.nvim_buf_add_highlight(bufnr, ns, hl, line, col_start, col_end)
        end
    end
end

local function dump_symbols()
    local bufnr = api.nvim_get_current_buf()

    local result = previous_result_buffer[bufnr]
    if not result then
        err_message("dump_symbols: semantic highlight is not enabled in the current buffer")
        return
    end

    local client_id = result.clientId 
    local client = lsp.get_client_by_id(client_id)
    if not client then
        err_message(string.format("dump_symbols: client %d is not active anymore", client_id))
        return
    end

    local data = result.data
    local types = client.resolved_capabilities.semantic_tokens_types
    local modifiers = client.resolved_capabilities.semantic_tokens_modifiers
    return parse_data(data, types, modifiers)
end

local function dump_cursor()
    local symbols = dump_symbols()
    local cursor_row, cursor_col = unpack(api.nvim_win_get_cursor(0))
    if not symbols then
        return
    end

    local cursor_symbol = nil
    for _,symbol in ipairs(symbols) do
        local sym_line = symbol.line + 1
        local sym_start = symbol.start
        local sym_end = sym_start + symbol.length

        if sym_line == cursor_row then
            if sym_start <= cursor_col and cursor_col < sym_end then
                return symbol
            end
        end
    end

    -- No symbol was found
    return
end

local function highlight_buffer(bufnr)
    lsp.buf_request(bufnr or 0, "textDocument/semanticTokens/full", {
        textDocument = util.make_text_document_params()
    })
end

local function enable_buffer(bufnr)
    highlight_buffer(bufnr)
    api.nvim_buf_call(bufnr, function()
        vim.cmd[[
        augroup lsp-semantic
            au!
            au CursorHold,InsertLeave <buffer> lua require'lsp-semantic'.highlight_buffer()
        augroup END
        ]]
    end)
end

local function disable_buffer(bufnr)
    api.nvim_buf_call(bufnr, function()
        vim.cmd[[
        augroup lsp-semantic
            au!
        augroup END
        ]]
    end)
    local ns = api.nvim_create_namespace("lsp-semantic-namespace")
    api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    previous_result_buffer[bufnr] = nil
end

local function before_init(initialize_params, config)
    local on_init = config.on_init
    config.on_init = function(client, result)
        modify_resolved_capabilities(client.server_capabilities, client.resolved_capabilities)

        client.handlers["textDocument/semanticTokens/full"] = lsp_handler_full

        if on_init then
            return on_init(client, result)
        end
    end

    local on_attach = config.on_attach
    config.on_attach = function(client, bufnr)
        enable_buffer(bufnr)
        api.nvim_buf_attach(bufnr, false, {
            on_detach = function()
                previous_result_buffer[bufnr] = nil
            end
        })

        if on_attach then
            return on_attach(client, bufnr)
        end
    end

    return modify_capabilities(initialize_params.capabilities)
end

return {
    before_init = before_init,
    enable_buffer = enable_buffer,
    disable_buffer = disable_buffer,
    highlight_buffer = highlight_buffer,
    dump_symbols = dump_symbols,
    dump_cursor = dump_cursor
}
