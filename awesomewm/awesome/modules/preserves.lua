local beautiful = require('beautiful')
local set_wallpaper = require('modules.utils.wallpaper').set_wallpaper

awesome.connect_signal('exit', function(reason_restart)
    if not reason_restart then return end

    local file = io.open('/tmp/awesomewm-last-selected-tags', 'w')

    if file == nil then return end

    for s in screen do
        if s.selected_tag then -- Check if there is a selected tag
            file:write(s.selected_tag.index, '\n')
        end
    end

    file:close()
end)

awesome.connect_signal('startup', function()
    local file = io.open('/tmp/awesomewm-last-selected-tags', 'r')
    if not file then
        -- Log error or notify user about file opening failure if needed
        return
    end

    local selected_tags = {}
    for line in file:lines() do
        local tag_index = tonumber(line)
        if tag_index then
            table.insert(selected_tags, tag_index)
        end
    end

    -- Iterate over each screen and apply saved tag indices
    for s in screen do
        local i = selected_tags[s.index]
        if i then
            local t = s.tags[i]
            if t then
                t:view_only()
            end
        end
    end

    file:close()
end)


-- awesome.connect_signal('exit', function(reason_restart)
--     if not reason_restart then return end
--
--     local file = io.open(os.getenv('HOME') .. '/.cache/awesome/wallpaper', 'w')
--     if file == nil then return end
--
--     file:write(current_wallpaper_path)
--
--     file:close()
-- end)

awesome.connect_signal('startup', function()
    local file = io.open(os.getenv('HOME') .. '/.cache/awesome/wallpaper', 'r')
    if not file then return end

    local wallpaper_path = file:read("*l")
    file:close()

    set_wallpaper(wallpaper_path)

end)
--
