local wezterm = require 'wezterm'

-- Import the summer color scheme
local summer_colors = {
    primary = {
        background = '#292A2B',
        -- background = background,
        foreground = '#AEB7B6',
    },
    normal = {
        black   = '#1d1f21',
        red     = '#CF3746',
        green   = '#7CBD27',
        yellow  = '#ECBD10',
        blue    = '#277AB6',
        magenta = '#AD4ED2',
        cyan    = '#32B5C7',
        white   = '#d8e2e1',
    },
    bright = {
        black   = '#292A2B',
        red     = '#d95473',
        green   = '#b6da74',
        yellow  = '#e7ca62',
        blue    = '#64a8d8',
        magenta = '#bc82d3',
        cyan    = '#65cedc',
        white   = '#ebf6f5',
    },
}

local config = {}
config.font_size = 14

config.line_height = 1.3

config.font = wezterm.font_with_fallback {
    {
        family = 'JetBrainsMono Nerd Font',
        weight = 'Bold',
    },
    -- Uncomment the following lines if you want to use FiraCode as a fallback
    -- {
    --     family = 'FiraCode Nerd Font',
    --     weight = 'Medium',
    -- },
}

config.font_rules = {
    {
        italic = true,
        font = wezterm.font('JetBrainsMono Nerd Font', { weight = 'Bold', style = 'Italic' }),
    },
    {
        intensity = 'Bold',
        font = wezterm.font('JetBrainsMono Nerd Font', { weight = 'ExtraBold' }),
    },
    {
        intensity = 'Bold',
        italic = true,
        font = wezterm.font('JetBrainsMono Nerd Font', { weight = 'ExtraBold', style = 'Italic' }),
    },
}


HOME = os.getenv("HOME")

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

config.window_background_opacity = file_exists(HOME .. '/.gnome') and 0.9 or 0.7
config.window_close_confirmation = 'NeverPrompt'
config.window_decorations = "RESIZE" -- Removes the top bar (title bar)
config.enable_tab_bar = false
config.enable_kitty_graphics=true
config.show_tabs_in_tab_bar = false
config.initial_cols = 72
config.initial_rows = 20

-- config.colors = {
--     background = summer_colors.primary.background,
--     foreground = summer_colors.primary.foreground,
--     cursor_bg = summer_colors.primary.foreground,
--     cursor_fg = summer_colors.primary.background,
--     ansi = {
--         summer_colors.normal.black,
--         summer_colors.normal.red,
--         summer_colors.normal.green,
--         summer_colors.normal.yellow,
--         summer_colors.normal.blue,
--         summer_colors.normal.magenta,
--         summer_colors.normal.cyan,
--         summer_colors.normal.white,
--     },
--     brights = {
--         summer_colors.bright.black,
--         summer_colors.bright.red,
--         summer_colors.bright.green,
--         summer_colors.bright.yellow,
--         summer_colors.bright.blue,
--         summer_colors.bright.magenta,
--         summer_colors.bright.cyan,
--         summer_colors.bright.white,
--     },
-- }

-- config.color_scheme = "Bamboo"
--
-- config.color_scheme = "Seti UI (Gogh)"
-- config.color_scheme = "Seti UI (Gogh)"
-- config.color_scheme = "Argonaut (Gogh)"
config.color_scheme = "Argonaut (Gogh)"
-- config.color_scheme = "Obsidian (Gogh)"
-- config.color_scheme = "Liquid Carbon Transparent (Gogh)"
-- config.color_scheme = "Summer Pop (Gogh)"
-- config.color_scheme = "Sweet Eliverlara (Gogh)"
-- config.color_scheme = "Dark Pastel (Gogh)"



config.colors ={
    background=summer_colors.primary.background,
    foreground=summer_colors.primary.foreground,
    cursor_bg = summer_colors.primary.foreground,
}

return config
