local awful = require('awful')
local naughty = require('naughty')

local M = {}

--- Toggles the mute state of the system's master volume.
-- @function mute
M.toggle_mute = function ()
    awful.spawn("amixer -q set Master toggle")
    awesome.emit_signal("volume_update")
end

--- Increases the system's master volume by a specified percentage.
-- @function increase_volume
-- @param percent number The percentage by which to increase the volume.
M.increase_volume = function (percent)
    if percent and tonumber(percent) then
        awful.spawn.spawn(string.format("amixer -q set Master %d%%+", tonumber(percent)))
    else
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Volume Control",
            text = "Invalid percentage for volume increase."
        })
    end
    awesome.emit_signal("volume_update")
end

--- Decreases the system's master volume by a specified percentage.
-- @param percent number The percentage by which to decrease the volume.
-- @function decrease_volume
M.decrease_volume = function (percent)
    if percent and tonumber(percent) then
        awful.spawn.spawn(string.format("amixer -q set Master %d%%-", tonumber(percent)))
    else
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Volume Control",
            text = "Invalid percentage for volume decrease."
        })
    end
    awesome.emit_signal("volume_update")
end

--- Retrieves the current volume and mute state of the system's master volume.
-- @function get_current_volume
-- @return number The current volume as a percentage or -1 if the volume is muted or cannot be determined.
M.get_current_volume = function ()
    local handle = io.popen("amixer sget Master")
    if not handle then return nil end
    local result = handle:read("*a")
    handle:close()

    local volume = result:match("Playback %d+ %[(%d+)%%%]")
    local is_muted = result:find("%[off%]") ~= nil

    if is_muted or not volume then
        return -1
    else
        return tonumber(volume)
    end
end

return M
