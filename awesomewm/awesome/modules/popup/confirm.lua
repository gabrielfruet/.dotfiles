local awful = require('awful')
local gears = require('gears')
local beautiful = require('beautiful')
local wibox = require('wibox')

local defs = require('modules.definitions')
local utils = require('modules.utils')

local M = {}

local confirm_options = {
    {text='Yes'},
    {text='No'},
}

local defaults = {
    message = 'Do you really want to do this?',
    on_confirm = function() end,
    on_decline = function() end
}

M.create = function (opts)
    opts = utils.table.merge_defaults(defaults, opts)

    local popup = awful.popup {
        ontop = true,
        visible = false, -- should be hidden when created
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, 4)
        end,
        maximum_width = 400,
        opacity=0.8,
        offset = { y = 5 , x = -5},
        widget = {}
    }

    local options_widget = { 
        layout = wibox.layout.flex.horizontal,
    }

    for _,v in pairs(confirm_options) do
        local wi = wibox.widget {
            {
                {
                    {
                        id = 'text',
                        align = 'center',
                        text = v.text,
                        widget = wibox.widget.textbox
                    },
                    margins=8,
                    widget=wibox.container.margin
                },
                bg = defs.colors.unselected_bg,
                fg = defs.colors.unselected_fg,
                id = 'bg_role',
                shape = gears.shape.rounded_rect,
                widget=wibox.container.background
            },
            margins=4,
            widget=wibox.container.margin
        }

        local wibg = wi:get_children_by_id('bg_role')[1]

        wi:connect_signal("mouse::enter", function(c)
            wibg:set_bg(defs.colors.selected_bg)
            wibg:set_fg(defs.colors.selected_fg)
        end)

        wi:connect_signal("mouse::leave", function(c)
            wibg:set_bg(defs.colors.unselected_bg)
            wibg:set_fg(defs.colors.unselected_fg)
        end)

        local tocall_on_click

        if v.text == 'Yes' then
            tocall_on_click = opts.on_confirm
        else
            tocall_on_click = opts.on_decline
        end

        wi:buttons(
            awful.util.table.join(
                awful.button({}, 1, function()
                    tocall_on_click()
                    popup.visible = false
                end))
        )
        table.insert(options_widget,wi)
    end

    local message_widget = {
        {
            {
                {
                    text=opts.message,
                    widget=wibox.widget.textbox
                },
                widget = wibox.container.margin,
                margins = 8,
            },
            widget = wibox.container.constraint,
            width = 100,
        },
        options_widget,
        layout = wibox.layout.fixed.vertical
    }

    popup:setup(message_widget)

    return popup
end

return M
