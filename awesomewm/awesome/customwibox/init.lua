local awful = require('awful')
local wibox = require('wibox')
local gears = require('gears')
local beautiful = require('beautiful')
local vicious = require("vicious")

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

M.mytaglist =  function(s)
    local names = {'5'}
    local l = awful.layout.suit  -- Just to save some typing: use an alias.
    local layouts = { l.tile, l.tile, l.floating, l.fair, l.max,
        l.floating, l.tile.left, l.floating, l.floating }
    awful.tag(names, s, layouts)
    local awesomepath = os.getenv("HOME") .. '/.config/awesome'
    awful.tag.add("Terminal", {
        icon = gears.surface.load_uncached(awesomepath .. "/icons/terminal_icon.png"),
        layout = awful.layout.suit.tile,
        screen = s,
        icon_only=true,
        index=1,
    })

    awful.tag.add("Browser", {
        icon = gears.surface.load_uncached(awesomepath .. "/icons/browser_icon.png"),
        layout = awful.layout.suit.tile,
        screen = s,
        icon_only=true,
        index=2
    })

    awful.tag.add("Spotify", {
        icon = gears.surface.load_uncached(awesomepath .. "/icons/song_icon.png"),
        layout = awful.layout.suit.floating,
        screen = s,
        icon_only=true,
        index=3
    })

    awful.tag.add("Discord", {
        icon = gears.surface.load_uncached(awesomepath .. "/icons/discord-white-icon.webp"),
        layout = awful.layout.suit.floating,
        screen = s,
        icon_only=true,
        index=4
    })
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
                local img_widget = self:get_children_by_id('icon_role')[1]
                local img = gears.surface.load_uncached(tag.icon)
                img_widget.image = img
                tag:connect_signal('property::selected', function()
                    img_widget.image = gears.color.recolor_image(img, THEME.get_current_theme().foreground)
                end)
            end,
            update_callback = function(self, tag, index, tags)
                local img_widget = self:get_children_by_id('icon_role')[1]
                local img = gears.surface.load_uncached(tag.icon)
                img_widget.image = img
                if tag.selected then
                    img_widget.image = gears.color.recolor_image(img, THEME.get_current_theme().background)
                else
                    img_widget.image = gears.color.recolor_image(img, THEME.get_current_theme().foreground)
                end
            end,
        },
    } end

M.mytasklist = function(s)
    return awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        style = {
            shape = gears.shape.powerline,
        },
        layout = {
            spacing = -13,
            layout  = wibox.layout.fixed.horizontal
        },
        widget_template = {
            {
                {
                    {
                        id     = 'text_role',
                        widget = wibox.widget.textbox,
                    },
                    left  = 20,
                    right = 20,
                    widget = wibox.container.margin,
                },
                widget = wibox.container.constraint,
                width = 100,
                strategy ='exact'
            },
            id     = 'background_role',
            widget = wibox.container.background,
        },
    }

end

return M
