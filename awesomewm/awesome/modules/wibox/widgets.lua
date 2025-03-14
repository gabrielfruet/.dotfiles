local vicious = require('vicious')
local wibox = require('wibox')
local gears = require('gears')
local awful = require('awful')
local beautiful = require('beautiful')
local volhandler = require('modules.handlers.volume')
local bathandler = require('modules.handlers.battery')
local naughty = require('naughty')
local defs = require('modules.definitions')
ICONSPATH = os.getenv('HOME') .. '/.config/awesome/icons'

local M = {}

M.ram = function()
    local ramwidget = wibox.widget.textbox()
    vicious.cache(vicious.widgets.mem)
    vicious.register(ramwidget, vicious.widgets.mem, defs.text_pango_wrapper("RAM $1%"), 10)
    return ramwidget
end

M.cpu = function()
    local cpuwidget = wibox.widget.textbox()
    vicious.cache(vicious.widgets.cpu)
    vicious.register(cpuwidget, vicious.widgets.cpu, defs.text_pango_wrapper("CPU $1%"), 10)
    return cpuwidget
end


M.bat = function(opts)
    if not bathandler.is_chargeable() then
        return nil
    end

    local icons = {
        charg = ICONSPATH .. "/batcharg.png",
        low = ICONSPATH .. "/batlow.png",
        half = ICONSPATH .. "/bathalf.png",
        ok = ICONSPATH .. "/batok.png",
        full = ICONSPATH .. "/batfull.png",
    }

    for k,v in pairs(icons) do
        icons[k] = gears.color.recolor_image(
            v,
            defs.colors.unselected_fg
        )
    end

    opts = opts ~= nil and opts or {}

    local markup = [[<span color='%s'><big><b>%s</b></big></span>]]
    local mybatwidget = wibox.widget{
        {
            {
                image=icons.low,
                widget=wibox.widget.imagebox,
            },
            widget=wibox.container.margin,
            bottom=7,
            top=7,
            right=7,
        },
        {
            widget=wibox.widget.textbox,
            markup=markup:format('#ff0000', '')
        },
        layout = wibox.layout.fixed.horizontal
    }

    local bat_update = function ()
        local percent = bathandler.bat_percentage()
        local color
        local icon
        if bathandler.is_charging() then
            color="#00ff00"
            icon = icons.charg
        elseif percent > 95 then
            color = defs.colors.unselected_fg
            icon = icons.full
        elseif percent > 60 then
            color = defs.colors.unselected_fg
            icon = icons.ok
        elseif percent > 40 then
            color = '#ffff00'
            icon = icons.half
        else
            color = '#ff0000'
            icon = icons.low
        end

        local children = mybatwidget.children
        children[1].widget.image = icon
        children[2].markup = markup:format(color, tostring(percent) .. '%')
    end

    gears.timer{
        timeout=opts.timeout ~= nil and opts.timeout or 10,
        autostart=true,
        call_now=true,
        callback=bat_update
    }
    bat_update()
    return mybatwidget
end


M.vol = function (opts)
    opts = opts ~= nil and opts or {}

    local icons = {
        muted=ICONSPATH .. '/muted.png',
        novol=ICONSPATH .. '/novol.png',
        halfvol=ICONSPATH .. '/halfvol.png',
        fullvol=ICONSPATH .. '/fullvol.png',
    }
    --loading icons
    for k,v in pairs(icons) do
        icons[k] = gears.color.recolor_image(
            v,
            defs.colors.unselected_fg
        )
    end

    MUTED = -1

    local widget =  wibox.widget{
        {
            {
                image=icons.muted,
                widget=wibox.widget.imagebox
            },
            widget=wibox.container.margin,
            left = 0,
            right = 5,
            bottom = 5,
            top = 5,
        },
        {
            markup='',
            widget=wibox.widget.textbox,
        },
        layout=wibox.layout.fixed.horizontal
    }

    local function update_volume()
        -- local volpercent = 
        volhandler.get_current_volume(function (volpercent)
            local children = widget.children
            local img_widget = children[1].children[1]
            local text_widget = children[2]

            if volpercent == MUTED then
                img_widget.image = icons.muted
                text_widget.markup = defs.text_pango_wrapper('Muted')
            else
                text_widget.markup = defs.text_pango_wrapper(tostring(volpercent) .. '%')
                if volpercent == 0 then
                    img_widget.image = icons.novol
                elseif volpercent < 50 then
                    img_widget.image = icons.halfvol
                else
                    img_widget.image = icons.fullvol
                end
            end

        end)
    end

    awesome.connect_signal("volume_update", update_volume)
    update_volume()

    widget:buttons(
        awful.util.table.join(
            awful.button({}, 1, function()
                volhandler.toggle_mute()
            end),
            awful.button({}, 4, function()
                volhandler.increase_volume(5)
            end),
            awful.button({}, 5, function()
                volhandler.decrease_volume(5)
            end))
    )

    return widget
end

M.power = function()
    local powericon = ICONSPATH .. '/power.png'
    powericon = gears.color.recolor_image(powericon, defs.colors.unselected_fg)
    local widget = wibox.widget {
        {
            image = powericon,
            resize = true,
            widget = wibox.widget.imagebox
        },
        margins = 2,
        widget = wibox.container.margin
    }

    local popup = require('modules.popup.power')

    widget:buttons(
        awful.util.table.join(
            awful.button({}, 1, function()
                if popup.visible then
                    popup.hide()
                else
                    popup:move_next_to(mouse.current_widget_geometry)
                end
            end))
    )

    return widget
end

return M
