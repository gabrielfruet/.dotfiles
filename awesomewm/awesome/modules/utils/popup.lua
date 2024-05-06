local utils_metatables = require('modules.utils.metatables')
local naughty = require('naughty')

local M = {}


local groups_popup = {}

local event_group_handler = {}

setmetatable(groups_popup, {
    __index = utils_metatables.default_value_on_index(function () return {} end)
})

setmetatable(event_group_handler, {
    __index = utils_metatables.default_value_on_index(function () return {} end)
})

--- Adds a popup or a table of popups to a specific group.
-- If a table of popups is passed, each popup in the table is added to the group recursively.
-- @param popups A popup identifier or a table of popup identifiers.
-- @param group The group identifier to which the popups will be added.
function M.add_popup_to_group(popups, group)
    for _,pop in pairs(popups) do
        groups_popup[group] = groups_popup[group] or {}
        table.insert(groups_popup[group], pop)
    end
end

--- Registers an event with a callback function to be triggered on a specific signal.
-- When the signal is emitted, the callback is executed for each popup in each group linked to the event.
-- @param event The event identifier.
-- @param callback The callback function to be executed.
-- @param signal The AwesomeWM signal that triggers the event.
function M.register_event_to_group(event, group, callback, call_when)
    event_group_handler[event] = event_group_handler[event] or {}
    event_group_handler[event][group] = callback

    local function callback_caller(...)
        callback(groups_popup[group], ...)
    end

    call_when(callback_caller)
end

function M.impl_is_mouse_ontop(popup)
    popup:connect_signal('mouse:enter', function ()
        popup.is_mouse_ontop = true
    end)

    popup:connect_signal('mouse:leave', function ()
        popup.is_mouse_ontop = false
    end)
end

return M
