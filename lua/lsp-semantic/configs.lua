local vim = vim
local lsp_semantic = require'lsp-semantic'

local dirpath = debug.getinfo(1, 'S').source:match("@(.*[/\\])")
local configs = {}

return setmetatable({}, {
    __index = function (tbl, key)
        -- dofile is used here as a performance hack to increase the speed of calls to setup({})
        -- dofile does not cache module lookups, and requires the absolute path to the target file
        local ok, val = pcall(dofile, string.format('%sservers/%s.lua', dirpath, key))
        
        if ok then
            rawset(tbl, key, val)
        end

        return val
    end
})
