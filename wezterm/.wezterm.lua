-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- For example, changing the color scheme:
-- config.color_scheme = "Batman"

-- FONTS AND COLOURS
config.font = wezterm.font("JetBrains Mono")
config.font_size = 13.5 -- default is 12

config.use_fancy_tab_bar = false

config.colors = {
    cursor_bg = "#97cda9",
    tab_bar = {
        background = "#0b0022",
        active_tab = {
            bg_color = "#2b2042",
            fg_color = "#c0c0c0",
            -- Specify whether you want "Half", "Normal" or "Bold" intensity for the
            -- label shown for this tab.
            -- The default is "Normal"
            intensity = "Normal",
            -- Specify whether you want "None", "Single" or "Double" underline for
            -- label shown for this tab.
            -- The default is "None"
            underline = "Double",
            italic = false,
            strikethrough = false,
        },
        inactive_tab = {
            bg_color = "#1b1032",
            fg_color = "#808080",
        },
        inactive_tab_hover = {
            bg_color = "#3b3052",
            fg_color = "#909090",
            italic = true,
        },
        new_tab = {
            bg_color = "#1b1032",
            fg_color = "#808080",
        },
        new_tab_hover = {
            bg_color = "#3b3052",
            fg_color = "#909090",
            italic = true,
        },
    },
}

-- HYPERLINKS
-- Use the defaults as a base
config.hyperlink_rules = wezterm.default_hyperlink_rules()
-- make task numbers clickable
-- the first matched regex group is captured in $1.
table.insert(config.hyperlink_rules, {
    regex = [[\b[tt](\d+)\b]],
    format = "https://example.com/tasks/?t=$1",
})
-- make username/project paths clickable. this implies paths like the following are for github.
-- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wez/wezterm | "wez/wezterm.git" )
-- as long as a full url hyperlink regex exists above this it should not match a full url to
-- github or gitlab / bitbucket (i.e. https://gitlab.com/user/project.git is still a whole clickable url)
table.insert(config.hyperlink_rules, {
    regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
    format = "https://www.github.com/$1/$3",
})

-- KEYBINDINGS FOR NATURAL KEY MOTIONS
local action = wezterm.action
config.keys = {
    { mods = "OPT", key = "LeftArrow", action = action.SendKey({ mods = "ALT", key = "b" }) },
    { mods = "OPT", key = "RightArrow", action = action.SendKey({ mods = "ALT", key = "f" }) },
    { mods = "CMD", key = "LeftArrow", action = action.SendKey({ mods = "CTRL", key = "a" }) },
    { mods = "CMD", key = "RightArrow", action = action.SendKey({ mods = "CTRL", key = "e" }) },
    { mods = "CMD", key = "Backspace", action = action.SendKey({ mods = "CTRL", key = "u" }) },
}

return config
