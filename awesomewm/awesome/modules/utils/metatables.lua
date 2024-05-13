local M = {}

function M.default_value_on_index(default)
    if type(default) == 'function' then
        return function (table, index)
            return default(table,index)
        end
    else
        return function (_, _)
            return default
        end
    end
end

return M
