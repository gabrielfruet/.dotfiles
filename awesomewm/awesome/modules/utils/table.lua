local M = {}

--- Merge default values with a user-provided table.
-- This function creates a new table that combines the `input` table with 
-- default values specified in the `defaults` table. Keys in the `defaults` 
-- table that are not present in the `input` table will be added to the result.
-- If `input` is nil, it returns an empty table initialized with default values.
--
-- @param defaults table The table containing default key-value pairs.
-- @param input table The table provided by the user. It may be nil.
-- @return table A new table with merged values from both `defaults` and `input`.
M.merge_defaults = function (defaults, input)
    local result = {}
    for k, v in pairs(input) do
        result[k] = v
    end

    if input == nil then return result end

    for k, v in pairs(defaults) do
        if result[k] == nil then
            result[k] = v
        end
    end

    return result
end

return M
