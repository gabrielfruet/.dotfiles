local awful = require('awful')
local utils_metatables = require('modules.utils.metatables')

local M = {}

local keys_callback = {}

setmetatable(keys_callback, {
    __index = utils_metatables.default_value_on_index(function () return {} end)
})

function M.register_key(key, callback)
    keys_callback[key] = keys_callback[key] or {}
    table.insert(keys_callback[key], callback)
end

return M
