local gears = require('gears')
local awful = require('awful')
local M = {}

function M.preview_wallpaper(wallpaper)
    if wallpaper then
        for s in screen do
            gears.wallpaper.maximized(wallpaper, s, false)
        end
    end
end

function M.set_wallpaper(wallpaper, reload)
    current_wallpaper_path = wallpaper
    M.preview_wallpaper(wallpaper)
    awful.spawn.easy_async_with_shell('wal -stn -i "' .. wallpaper .. '" --backend haishoku', function ()
        if reload == true then
            awesome.restart()
        end
    end)
end

return M
