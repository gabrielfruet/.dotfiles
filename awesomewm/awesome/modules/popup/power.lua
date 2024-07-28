local awful = require('awful')
local gears = require('gears')
local beautiful = require('beautiful')
local wibox = require('wibox')
local confirmpp = require('modules.popup.confirm')
local defs = require('modules.definitions')
local utils = require('modules.utils')
local naughty = require('naughty')
--local defs = require('modules.definitions')
ICONSPATH = os.getenv('HOME') .. '/.config/awesome/icons'

local menu_items = {
    {name='Log-out', icon=ICONSPATH .. '/log-out.png', cmd='awesome-client "awesome.quit()"', message='Are you sure you want to log-out?'},
    {name='Reboot', icon=ICONSPATH .. '/loop.png', cmd='systemctl reboot', message='Are you sure you want to reboot?'},
    {name='Suspend', icon=ICONSPATH .. '/moon.png', cmd='systemctl suspend', message='Are you sure you want to suspend?'},
    {name='Hibernate', icon=ICONSPATH .. '/hibernation.png', cmd='systemctl hibernate', message='Are you sure you want to hibernate?'},
    {name='Lock', icon=ICONSPATH .. '/lock.png', cmd='awesome-client "require(\'awful\').spawn(\'i3lock\')"', message='Are you sure you want to lock?'},
    {name='Shutdown', icon=ICONSPATH .. '/power.png', cmd='systemctl poweroff', message='Are you sure you want to shutdown?'},
}

local function text_markup(text)
    return text
end

local popup = awful.popup {
    ontop = true,
    visible = false, -- should be hidden when created
    shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, 4)
    end,
    preferred_positions = 'bottom',
    maximum_width = 400,
    offset = { y = 5 },
    opacity=defs.opacity,
    widget = {}
}

local rows = { layout = wibox.layout.fixed.vertical }

local SELECTED_COLOR_FG = defs.colors.selected_fg
local UNSELECTED_COLOR_FG = defs.colors.unselected_fg
local SPECIAL_COLOR_FG = defs.colors.red


local active_confirmation_popup = nil

local function base_after_choice()
    if active_confirmation_popup ~= nil then
        active_confirmation_popup.hide()
        active_confirmation_popup = nil
    end
end

local function on_confirmation(opts)
    if opts == nil or opts.cmd == nil then
        base_after_choice()
    else
        local specific_confirmation = function ()
            awful.spawn.spawn(opts.cmd)
            base_after_choice()
        end
        return specific_confirmation
    end
end

local function on_decline()
    base_after_choice()
end

local confirmation_popup_cache = {}

local hover_timer = gears.timer({
    timeout = 0.5,
    autostart = false,
    single_shot=true,
    callback = function ()
        if not popup.is_mouse_ontop and (active_confirmation_popup == nil or not active_confirmation_popup.is_mouse_ontop) then
            popup.hide()
        end
    end
})

local function get_confirmation_popup(item)
    if confirmation_popup_cache[item.name] ~= nil then return confirmation_popup_cache[item.name] end

    confirmation_popup_cache[item.name] = confirmpp.create{
        message = item.message,
        on_confirm = on_confirmation({cmd=item.cmd}),
        on_decline = on_decline,
        on_leave = function ()
           hover_timer:start()
        end,
        on_enter = function ()
            if hover_timer.started then
                hover_timer:stop()
            end
        end
    }
    return confirmation_popup_cache[item.name]
end

local function confirmation_focus_on(item)
    if active_confirmation_popup ~= nil then
        active_confirmation_popup.hide()
    end
    active_confirmation_popup = get_confirmation_popup(item)
    active_confirmation_popup:move_next_to(mouse.current_widget_geometry)
    active_confirmation_popup.visible = true
end


for _, item in ipairs(menu_items) do
    local icon = {
        selected = gears.surface.load_uncached(gears.color.recolor_image(item.icon, SELECTED_COLOR_FG))
    }

    local unselected_color = item.name == 'Shutdown' and SPECIAL_COLOR_FG or UNSELECTED_COLOR_FG

    icon.unselected = gears.surface.load_uncached(gears.color.recolor_image(item.icon, unselected_color))

    local row = wibox.widget {
        {
            {
                {
                    id = 'icon',
                    image = icon.unselected,
                    forced_width = 16,
                    forced_height = 16,
                    widget = wibox.widget.imagebox
                },
                {
                    markup = text_markup(item.name),
                    widget = wibox.widget.textbox,
                },
                spacing=12,
                layout = wibox.layout.fixed.horizontal
            },
            widget = wibox.container.margin,
            margins=8,
        },
        widget = wibox.container.background
    }

    local iconwidget = row:get_children_by_id('icon')[1]


    row:connect_signal("mouse::enter", function(c)
        if not popup.visible then return end
        c:set_bg(defs.colors.selected_bg)
        c:set_fg(defs.colors.selected_fg)
        iconwidget.image = icon.selected
    end)
    row:connect_signal("mouse::leave", function(c)
        if not popup.visible then return end
        c:set_bg(defs.colors.unselected_bg)
        c:set_fg(defs.colors.unselected_fg)
        iconwidget.image = icon.unselected
    end)

    local old_cursor, old_wibox
    row:connect_signal("mouse::enter", function()
        if not popup.visible then return end
        local wb = mouse.current_wibox
        old_cursor, old_wibox = wb.cursor, wb
        wb.cursor = "hand1"
    end)
    row:connect_signal("mouse::leave", function()
        if not popup.visible then return end
        if old_wibox then
            old_wibox.cursor = old_cursor
            old_wibox = nil
        end
    end)

    row:buttons(
        awful.util.table.join(
            awful.button({}, 1, function()
                confirmation_focus_on(item)
            end))
    )

    table.insert(rows, row)
end

popup:setup(rows)

popup.is_mouse_ontop = false

popup:connect_signal('mouse::enter', function ()
    if not popup.visible then return end
    if hover_timer.started then
        hover_timer:stop()
    end
    popup.is_mouse_ontop = true
end)

popup:connect_signal('mouse::leave', function ()
    if not popup.visible then return end
    hover_timer:start()
    popup.is_mouse_ontop = false
end)

popup.hide = function ()
    popup.visible = false
    on_decline()
end

popup:connect_signal('property::visible', function ()
    hover_timer:start()
end)

return popup
