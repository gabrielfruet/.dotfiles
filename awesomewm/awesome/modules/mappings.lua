local awful = require("awful")
local gears = require("gears")
local volhandler = require('modules.handlers.volume')

local noop = function () end

local custom_keys = gears.table.join(

    -- Volume mapings
    awful.key({ modkey }, "F10", function() volhandler.toggle_mute() end, {description = "toggle mute", group = "audio"}),
    awful.key({ modkey }, "F11", function() volhandler.decrease_volume(5) end, {description = "decrease volume by 5%", group = "audio"}),
    awful.key({ modkey }, "F12", function() volhandler.increase_volume(5) end, {description = "increase volume by 5%", group = "audio"}),
    awful.key({  }, "XF86AudioNext", function() awful.spawn.easy_async('playerctl next', noop) end, {description = "next song", group = "audio"}),
    awful.key({  }, "XF86AudioPrev", function() awful.spawn.easy_async('playerctl previous', noop) end, {description = "previous song", group = "audio"}),
    awful.key({  }, "XF86AudioPlay", function() awful.spawn.easy_async('playerctl play-pause', noop) end, {description = "play pause", group = "audio"})
)

return custom_keys
