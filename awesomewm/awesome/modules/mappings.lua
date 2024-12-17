local awful = require("awful")
local gears = require("gears")
local volhandler = require('modules.handlers.volume')

local custom_keys = gears.table.join(

    -- Volume mapings
    awful.key({ modkey }, "F10", function() volhandler.toggle_mute() end, {description = "toggle mute", group = "audio"}),
    awful.key({ modkey }, "F11", function() volhandler.decrease_volume(5) end, {description = "decrease volume by 5%", group = "audio"}),
    awful.key({ modkey }, "F12", function() volhandler.increase_volume(5) end, {description = "increase volume by 5%", group = "audio"})
)

return custom_keys
