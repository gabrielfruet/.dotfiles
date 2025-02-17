local gears = require('gears')
local beautiful = require('beautiful')

beautiful.init(gears.filesystem.get_themes_dir() .. "xresources/theme.lua")
-- beautiful.font = 'JetBrainsMonoNerdFontMono-ExtraBold 9'
beautiful.font = 'Roboto 9'
beautiful.hotkeys_font = 'Roboto 12'
beautiful.hotkeys_description_font = 'Roboto 12'
THEME = beautiful.xresources

local M = {}

-- M.opacity_hex = 'cc'
-- M.opacity_hex = '7F'
M.opacity_hex = '50'
M.opacity = 1.0
-- M.opacity = 0.8
M.colors = {}

local main_color = THEME.get_current_theme().color13 -- Adjust the color as needed
local shine_color = '#ffffff'

-- Create a linear gradient pattern
-- Adjust the coordinates to control the direction of the gradient
local gradient = gears.color.create_linear_pattern{
    type = "linear",
    from = { 0, -30 }, -- Gradient starts from the top
    to = { 0, 15 },   -- Gradient ends 30 pixels down
    stops = {
        { 0, shine_color },  -- Start with a shine at the top
        { 1, main_color }, -- Transition to the main color in the middle
    }
}

M.text_pango_wrapper = function (text)
    return string.format('<span foreground=\'%s\'><big><b>%s</b></big></span>', M.colors.unselected_fg, text)
end

beautiful.useless_gap = 8
beautiful.border_width = 1
beautiful.tasklist_bg_normal = THEME.get_current_theme().background .. '00'

--beautiful.taglist_bg_focus = THEME.get_current_theme().color10
beautiful.taglist_bg_focus = gradient
beautiful.tasklist_bg_focus = gradient

M.colors.selected_bg = gradient
M.colors.selected_fg = THEME.get_current_theme().background
M.colors.unselected_fg = '#eeeec0'
M.colors.unselected_bg = THEME.get_current_theme().background .. M.opacity_hex
M.colors.red = '#cc3333'

return M
