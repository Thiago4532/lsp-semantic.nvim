local vim = vim
local lsp_semantic = require'lsp-semantic'

local dirpath = debug.getinfo(1, 'S').source:match("@(.*[/\\])")
local configs = {}

local mt = {}
function mt:__index(key)
    if configs[key] == nil then
        -- dofile is used here as a performance hack to increase the speed of calls to setup({})
        -- dofile does not cache module lookups, and requires the absolute path to the target file
        configs[key] = dofile(dirpath .. 'servers/' .. key .. '.lua')
    end
    return configs[key]
end

return setmetatable({}, mt)
