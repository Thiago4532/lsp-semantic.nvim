local lsp_semantic = require'lsp-semantic'
local vim = vim

local semantic_highlight = {
    -- custom_types = {
    --     ["variable"] = "Purple"
    -- }
}

return {
    before_init = function(initialize_params, config)
        config.semantic_highlight = vim.tbl_extend("keep",
                                                   config.semantic_highlight or {},
                                                   semantic_highlight)
        return lsp_semantic.before_init(initialize_params, config)
    end
}
