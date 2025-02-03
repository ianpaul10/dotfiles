local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- For example, changing the color scheme:
-- config.color_scheme = "Batman"

-- PADDING FOR NVIM
config.window_padding = {
    left = 1,
    right = 1,
    top = 1,
    bottom = 1,
}

-- FONTS AND COLOURS
config.font = wezterm.font("JetBrains Mono")
config.font_size = 13.5 -- default is 12

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

config.audible_bell = "Disabled"

-- KEYBINDINGS
config.keys = {
    {
        key = "9",
        mods = "ALT",
        action = action.ShowLauncher,
        -- action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|TABS" }),
    },
}

-- TAB BAR
config.use_fancy_tab_bar = false

-- Time and system status in right status
wezterm.on("update-right-status", function(window, pane)
  -- Get current time
  local time = wezterm.strftime("%H:%M")
  
  -- Get battery info
  local battery = ""
  for _, b in ipairs(wezterm.battery_info()) do
    battery = string.format("%.0f%%", b.state_of_charge * 100)
  end

  -- Get system information using wezterm's built-in functions
  local success, stdout, stderr = wezterm.run_child_process({"bash", "-c", [[
    cpu_usage=$(top -l 1 | grep -E "^CPU" | grep -Eo '[^[:space:]]+%' | head -1)
    memory=$(memory_pressure | grep "System-wide memory free percentage:" | awk '{print $5}')
    echo "$cpu_usage|$memory%"
  ]]})

  local cpu_usage = "CPU: ?"
  local mem_usage = "RAM: ?"
  
  -- Helper function to split string
  local function split_string(str, sep)
    local parts = {}
    for part in string.gmatch(str, "([^" .. sep .. "]+)") do
      table.insert(parts, part)
    end
    return parts
  end

  if success then
    local cleaned = stdout:gsub("\n", "")
    local parts = split_string(cleaned, "|")
    if #parts == 2 then
      cpu_usage = "CPU: " .. parts[1]
      mem_usage = "RAM: " .. parts[2]
    end
  end

  -- Set the right status with all metrics
  window:set_right_status(wezterm.format({
    { Background = { Color = "#0b0022" } },
    { Foreground = { Color = "#c0c0c0" } },
    { Text = string.format(" %s  %s  %s  %s  %s ", cpu_usage, mem_usage, battery, time, wezterm.nerdfonts.fa_apple) },
  }))
end)

return config
