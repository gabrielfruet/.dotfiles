local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local defs = require('modules.definitions')
local modules_wibox_widgets = require('modules.wibox.widgets')

local M = {}

local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  c:emit_signal(
                                                      "request::activate",
                                                      "tasklist",
                                                      {raise = true}
                                                  )
                                              end
                                          end),
                     awful.button({ }, 3, function()
                                              awful.menu.client_list({ theme = { width = 250 } })
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))
local function add_icon_tags(icon_tags, screen)
    for i,v in ipairs(icon_tags) do
        local icon
        if type(v.icon) == 'string' then
            icon = gears.surface.load_uncached(v.icon)
        else
            icon = v.icon
        end

        local tag_tbl = {
            icon=icon,
            layout=v.layout,
            screen = screen,
            index=i,
            icon_only=true,
        }
        awful.tag.add(v[1], tag_tbl)
    end
end

M.mytaglist =  function(s)
    local awesomepath = os.getenv("HOME") .. '/.config/awesome'
    local l = awful.layout.suit
    add_icon_tags({
        {
            "Terminal",
            icon=awesomepath .. "/icons/terminal_icon.png",
            layout=l.tile
        },
        {
            "Browser",
            icon=awesomepath .. "/icons/browser2.png",
            layout=l.tile
        },
        {
            "Home",
            icon=awesomepath .. "/icons/home_white.png",
            layout=l.float
        },
        {
            "Folder",
            icon=awesomepath .. "/icons/folder2.png",
            layout=l.tile
        },
        {
            "Spotify",
            icon=awesomepath .. "/icons/song_icon.png",
            layout=l.tile
        },
        {
            "Discord",
            icon=awesomepath .. "/icons/chat.png",
            layout=l.tile
        },
    }, s)
    awful.tag({}, s, {})
    return awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons,
        widget_template = {
            {
                {
                    {
                        {
                            {
                                id     = 'text_role',
                                widget = wibox.widget.textbox,
                            },
                            {
                                id     = 'icon_role',
                                widget = wibox.widget.imagebox,
                            },
                            layout = wibox.layout.fixed.horizontal
                        },
                        margins=6,
                        widget  = wibox.container.margin,
                    },
                    layout = wibox.layout.fixed.horizontal,
                },
                left  = 8,
                right = 8,
                top = -2,
                bottom = -2,
                widget = wibox.container.margin
            },
            id = 'background_role',
            widget = wibox.container.background,
            create_callback = function(self, tag, index, tags)
                SELECTED_COLOR = defs.colors.selected_fg
                UNSELECTED_COLOR = defs.colors.unselected_fg
                local img_widget = self:get_children_by_id('icon_role')[1]
                local img = tag.icon
                tag:connect_signal('property::selected', function()
                    img_widget.image = gears.color.recolor_image(img, SELECTED_COLOR)
                end)

                if tag.selected then
                    img_widget.image = gears.color.recolor_image(img, SELECTED_COLOR)
                else
                    img_widget.image = gears.color.recolor_image(img, UNSELECTED_COLOR)
                end
            end,
            update_callback = function(self, tag, index, tags)
                SELECTED_COLOR = defs.colors.selected_fg
                UNSELECTED_COLOR = defs.colors.unselected_fg
                local img_widget = self:get_children_by_id('icon_role')[1]
                local img = gears.surface.load_uncached(tag.icon)
                img_widget.image = img
                if tag.selected then
                    img_widget.image = gears.color.recolor_image(img, SELECTED_COLOR)
                else
                    img_widget.image = gears.color.recolor_image(img, UNSELECTED_COLOR)
                end
            end,
        },
    } end

M.mytasklist = function(s)
    return awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        -- style = {
        --     shape = gears.shape.circle
        -- },
        widget_template = {
            {
                {
                    {
                        id     = 'icon_role',
                        widget = wibox.widget.imagebox,
                    },
                    widget = wibox.layout.fixed.horizontal,
                },
                left = 10,
                right = 10,
                top=4,
                bottom=4,
                widget = wibox.container.margin,
            },
            id     = 'background_role',
            widget = wibox.container.background,
        },
    }

end

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

M.wibox_init = function() awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)


    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    s.mytextclock = wibox.widget.textclock(defs.text_pango_wrapper('%A %b %d, %H:%M'))
    -- Create a promptbox for each screen
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen. s.mylayoutbox = awful.widget.layoutbox(s) s.mylayoutbox:buttons(gears.table.join(
        awful.button({ }, 1, function () awful.layout.inc( 1) end),
        awful.button({ }, 3, function () awful.layout.inc(-1) end),
        awful.button({ }, 4, function () awful.layout.inc( 1) end),
        awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = M.mytaglist(s)
    s.mytasklist = M.mytasklist(s)

    local ramwidget = modules_wibox_widgets.ram()
    local cpuwidget = modules_wibox_widgets.cpu()
    local batwidget = modules_wibox_widgets.bat()
    local volwidget = modules_wibox_widgets.vol()
    local powwidget = modules_wibox_widgets.power()

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s , bg = beautiful.bg_normal .. defs.opacity_hex, height=25})
    -- Add widgets to the wibox
    s.mywibox:setup {
        bg=defs.colors.unselected_bg,
        layout = wibox.layout.align.horizontal,
        expand = "none",
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            --mylauncher,
            s.mytaglist,
            s.mypromptbox,
            {
                s.mytasklist,
                widget=wibox.container.margin,
                left = 10,
            },
        },
        s.mytextclock,
        { -- Right widgets
            {
                cpuwidget,
                ramwidget,
                volwidget,
                batwidget,
                mykeyboardlayout,
                layout=wibox.layout.fixed.horizontal,
                spacing=20,
                spacing_widget={
                    color=beautiful.taglist_bg_focus,
                    widget=wibox.widget.separator,
                    orientation="vertical",
                    thickness=2,
                    span_ratio=0.6
                }
            },
            {
                wibox.widget.systray(),
                powwidget,
                s.mylayoutbox,
                layout = wibox.layout.fixed.horizontal,
            },
            layout = wibox.layout.fixed.horizontal,
        },
    }

end)
end

return M
