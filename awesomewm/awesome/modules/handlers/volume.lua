local awful = require('awful')
local naughty = require('naughty')

local M = {}

--- Toggles the mute state of the system's master volume.
-- @function mute
M.toggle_mute = function ()
    -- awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")
    awful.spawn.easy_async_with_shell("pactl set-sink-mute @DEFAULT_SINK@ toggle", function ()
        awesome.emit_signal("volume_update")
    end)
end

--- Increases the system's master volume by a specified percentage.
-- @function increase_volume
-- @param percent number The percentage by which to increase the volume.
M.increase_volume = function (percent)
    if percent and tonumber(percent) then
        awful.spawn.easy_async_with_shell(string.format("pactl set-sink-volume @DEFAULT_SINK@ +%d%%", tonumber(percent)), function ()
            awesome.emit_signal("volume_update")
        end)
    else
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Volume Control",
            text = "Invalid percentage for volume increase."
        })
    end
end

--- Decreases the system's master volume by a specified percentage.
-- @param percent number The percentage by which to decrease the volume.
-- @function decrease_volume
M.decrease_volume = function (percent)
    if percent and tonumber(percent) then
        awful.spawn.easy_async_with_shell(string.format("pactl set-sink-volume @DEFAULT_SINK@ -%d%%", tonumber(percent)), function ()
            awesome.emit_signal("volume_update")
        end)
    else
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Volume Control",
            text = "Invalid percentage for volume decrease."
        })
    end
end

--- Retrieves the current volume and mute state of the system's master volume.
-- @function get_current_volume
-- @return number The current volume as a percentage or -1 if the volume is muted or cannot be determined.
M.get_current_volume = function (cb)
    -- local handle = io.popen("pactl get-sink-volume @DEFAULT_SINK@")
    -- if handle == nil then return nil end
    -- local volume_result = handle:read("*a")
    -- handle:close()
    awful.spawn.easy_async("pactl get-sink-volume @DEFAULT_SINK@", function (volume_result, vol_stderr, vol_reason,exit_code)
        awful.spawn.easy_async("pactl get-sink-mute @DEFAULT_SINK@", function (mute_result, mute_stderr, mute_reason, mute_exit_code)
            local volume = tonumber(volume_result:match("(%d+)%%")) -- extract the volume percentage
            local is_muted = mute_result:find("yes") ~= nil

            if is_muted or not volume then
                cb(-1)
            else
                cb(volume)
            end
        end
        )
    end
    )

    -- local handle_mute = io.popen("pactl get-sink-mute @DEFAULT_SINK@")
    -- if handle_mute == nil then return nil end
    -- local mute_result = handle_mute:read("*a")
    -- handle_mute:close()

    -- local volume = tonumber(volume_result:match("(%d+)%%")) -- extract the volume percentage
    -- local is_muted = mute_result:find("yes") ~= nil
    --
    -- if is_muted or not volume then
    --     return -1
    -- else
    --     return volume
    -- end
end
return M
