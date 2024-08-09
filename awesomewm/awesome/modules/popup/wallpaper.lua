local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local defs = require('modules.definitions')
local set_wallpaper = require('modules.utils.wallpaper').set_wallpaper
local preview_wallpaper = require('modules.utils.wallpaper').preview_wallpaper

local wallpaper_dir = os.getenv("HOME") .. "/wallpapers"
local initial_wallpaper = current_wallpaper_path

local popup = awful.popup {
    widget = wibox.widget{},
    ontop   = true,
    visible = false,
    shape   = gears.shape.rounded_rect,
    placement = awful.placement.centered,
    border_width = 2,
    border_color = beautiful.border_color
}

local function create_wallpaper_grid()
    local wallpapers_imgs = {}

    for file in io.popen('find '..wallpaper_dir..' -type f \\( -name "*.jpg" -o -name "*.png" \\)'):lines() do
        table.insert(wallpapers_imgs, file)
    end

    local rows = 3
    local cols = 3
    local grid = wibox.layout.grid()
    grid.min_cols_size = 10
    grid.min_rows_size = 10
    grid.homogeneous = true
    grid.expand = true

    local grid_widget = wibox.widget{
        {
            grid,
            margins = 10,
            widget  = wibox.container.margin
        },
        bg     = beautiful.bg_normal,
        opacity = defs.opacity,
        widget = wibox.container.background
    }

    grid_widget.current_row = 1

    local image_frames = {}
    local images = {}

    for i=1,rows*cols do
        local frame = wibox.widget {
            image  = nil,
            forced_width=200,
            forced_height=200,
            widget = wibox.widget.imagebox
        }

        frame:connect_signal("mouse::enter", function()
            preview_wallpaper(images[i])
        end)

        frame:connect_signal("button::press", function(_, _, _, button)
            if button == 1 and images[i] ~= nil then
                initial_wallpaper = images[i]
                set_wallpaper(initial_wallpaper, true)
                popup.visible = false
            end
        end)
        grid:add_widget_at(frame, math.floor((i-1)/cols) + 1, (i-1)%cols + 1, 1, 1)
        table.insert(image_frames, frame)
    end

    local function change_grid(diff)
        local start_row = math.min(
            math.max(
                grid_widget.current_row + diff,
                1
            ),
            math.ceil(#wallpapers_imgs / cols))

        grid_widget.current_row = start_row

        local starting = (start_row-1)*cols
        for i=1,rows*cols do
            local new_img
            if starting + i > #wallpapers_imgs then
                new_img = nil
            else
                new_img = wallpapers_imgs[starting+i]
            end
            image_frames[i].image = new_img
            images[i] = new_img

        end
    end

    change_grid(0)
    grid_widget.change_grid = change_grid

    return grid_widget
end

local grid_widget = create_wallpaper_grid()

popup.widget = grid_widget

--[[popup:connect_signal("button::press", function(_, _, _, button)
    if button == 4 then
        grid_widget.change_grid(1)
    elseif button == 5 then
        grid_widget.change_grid(-1)
    end
end)]]

popup:buttons(
    awful.util.table.join(
        awful.button({}, 4, function()
            grid_widget.change_grid(1)
        end),
        awful.button({}, 5, function()
            grid_widget.change_grid(-1)
        end))
)

globalkeys = gears.table.join(
    globalkeys,
    awful.key({ modkey }, "t", function()
        popup.visible = not popup.visible
        if not popup.visible then
            set_wallpaper(current_wallpaper_path)
        end
    end,
    {description = "show wallpaper selector", group = "custom"})
)

root.keys(globalkeys)

