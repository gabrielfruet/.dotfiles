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
    print('INFO: wallpaper: Saving wallpaper to ' .. current_wallpaper_path)
    M.preview_wallpaper(wallpaper)
    awful.spawn.easy_async_with_shell('wal -stn -i "' .. wallpaper .. '" --backend wal',
        function (stdout, stderr, exitreason, exitcode)
            print('INFO: wallpaper | wal stdout: ' .. stdout)
            print('INFO: wallpaper | wal stderr: ' .. stderr)
            print('INFO: wallpaper | wal exit code: ' .. exitcode)
            if reload == true then
                awesome.restart()
            end
        end)
end

return M
