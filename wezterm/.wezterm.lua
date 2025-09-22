local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- For example, changing the color scheme:
-- config.color_scheme = "Batman"

config.window_close_confirmation = "AlwaysPrompt"
config.skip_close_confirmation_for_processes_named = {} -- confirm for ALL tabs
config.native_macos_fullscreen_mode = true

-- PADDING FOR NVIM
config.window_padding = {
  left = 1,
  right = 1,
  top = 1,
  bottom = 1,
}

-- FONTS AND COLOURS
-- harfbuzz_features disables ligatures
config.font = wezterm.font({ family = "JetBrains Mono", harfbuzz_features = { "calt=0", "clig=0", "liga=0" } })
-- 12.5 for MBP 14", 13.5 for MBA 15"
config.font_size = 12.5 -- default is 12

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

-- KEYBINDINGS
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }
local action = wezterm.action
config.keys = {
  -- KEY MOTIONS
  { mods = "OPT", key = "LeftArrow", action = action.SendKey({ mods = "ALT", key = "b" }) },
  { mods = "OPT", key = "RightArrow", action = action.SendKey({ mods = "ALT", key = "f" }) },
  { mods = "CMD", key = "LeftArrow", action = action.SendKey({ mods = "CTRL", key = "a" }) },
  { mods = "CMD", key = "RightArrow", action = action.SendKey({ mods = "CTRL", key = "e" }) },
  { mods = "CMD", key = "Backspace", action = action.SendKey({ mods = "CTRL", key = "u" }) },
  -- wezterm launcher
  {
    key = "0",
    mods = "LEADER",
    action = action.ShowLauncher,
    -- action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|TABS" }), -- to enter in fuzzy mode automatically
  },
  -- PANE MANAGEMENT
  -- TODO: figure out how to make bot and right work nicely together. Maybe something to do with naming instead of relying on index?
  -- {
    -- Creates a new pane in the bottom if it doesn't exist, otherwise toggles showing and hiding the bottom pane/terminal
  --   key = ";",
  --   mods = "LEADER",
  --   action = wezterm.action_callback(function(_, pane)
  --     local tab = pane:tab()
  --     local panes = tab:panes_with_info()
  --     if #panes == 1 then
  --       pane:split({
  --         direction = "Bottom",
  --         size = 0.25,
  --       })
  --     elseif not panes[1].is_zoomed then
  --       panes[1].pane:activate()
  --       tab:set_zoomed(true)
  --     elseif panes[1].is_zoomed then
  --       tab:set_zoomed(false)
  --       panes[2].pane:activate()
  --     end
  --   end),
  -- },
  {
    -- Creates a new pane on the right if it doesn't exist, otherwise toggles showing and hiding the bottom pane/terminal
    key = "Space",
    mods = "LEADER",
    action = wezterm.action_callback(function(_, pane)
      local tab = pane:tab()
      local panes = tab:panes_with_info()
      if #panes == 1 then
        pane:split({
          direction = "Right",
          size = 0.30,
        })
      elseif not panes[1].is_zoomed then
        panes[1].pane:activate()
        tab:set_zoomed(true)
      elseif panes[1].is_zoomed then
        tab:set_zoomed(false)
        panes[2].pane:activate()
      end
    end),
  },
  { key = '"', mods = "LEADER", action = wezterm.action.SplitPane({ direction = "Right" }) },
  { key = "%", mods = "LEADER", action = wezterm.action.SplitPane({ direction = "Down" }) },
  {
    key = "w",
    mods = "LEADER",
    action = wezterm.action.CloseCurrentPane({ confirm = true }),
  },
  { mods = "LEADER", key = "j", action = action.ActivatePaneDirection("Down") },
  { mods = "LEADER", key = "k", action = action.ActivatePaneDirection("Up") },
  { mods = "LEADER", key = "h", action = action.ActivatePaneDirection("Left") },
  { mods = "LEADER", key = "l", action = action.ActivatePaneDirection("Right") },
  { mods = "LEADER", key = "f", action = action.ToggleFullScreen },
  { mods = "LEADER", key = "6", action = action.ActivateLastTab },
  -- WORKSPACE MANAGEMENT
  -- Prompt for a name to use for a new workspace and switch to it.
  {
    key = "n",
    mods = "LEADER",
    action = action.PromptInputLine({
      description = wezterm.format({
        { Attribute = { Intensity = "Bold" } },
        { Foreground = { AnsiColor = "Fuchsia" } },
        { Text = "Enter name for new workspace" },
      }),
      action = wezterm.action_callback(function(window, pane, line)
        -- line will be `nil` if they hit escape without entering anything
        -- An empty string if they just hit enter
        -- Or the actual line of text they wrote
        if line then
          window:perform_action(
            action.SwitchToWorkspace({
              name = line,
            }),
            pane
          )
        end
      end),
    }),
  },
  { mods = "LEADER", key = "=", action = action.ResetFontSize },
  -- SCROLL
  { mods = "SHIFT", key = "UpArrow", action = wezterm.action.ScrollToPrompt(-1) },
  { mods = "SHIFT", key = "DownArrow", action = wezterm.action.ScrollToPrompt(1) },
  { mods = "CMD", key = "u", action = wezterm.action.ScrollByPage(-0.5) }, -- can't use CTRL b/c that overrides nvim's impl.
  { mods = "CMD", key = "d", action = wezterm.action.ScrollByPage(0.5) },
}

config.audible_bell = "Disabled"

-- TAB BAR
config.default_workspace = "dflt"
config.use_fancy_tab_bar = false

wezterm.on("update-right-status", function(window, pane)
  local time = wezterm.strftime("%H:%M")
  local date = wezterm.strftime("%a %b %d") -- Day of week (short), Month (short), Day

  local battery = ""
  for _, b in ipairs(wezterm.battery_info()) do
    battery = string.format("%.0f%%", b.state_of_charge * 100)
  end

  local workspace_name = window:active_workspace()
  if workspace_name == nil then
    workspace_name = "n/a"
  end

  --   -- Get system information using wezterm's built-in functions
  --   local success, stdout, stderr = wezterm.run_child_process({
  --       "bash",
  --       "-c",
  --       [[
  --   cpu_usage=$(top -l 2 | grep -E "^CPU" | tail -1 | awk '{print $3}' | sed 's/,//')
  --   memory=$(vm_stat | awk '/free/ {free=$3} /active/ {active=$3} /inactive/ {inactive=$3} /speculative/ {speculative=$3} /wired/ {wired=$4} END {total=(free+active+inactive+speculative+wired)*4096/1024/1024/1024; printf "%.1f", total}')
  --   echo "$cpu_usage|${memory}GB"
  -- ]],
  --   })
  --   local cpu_usage = "CPU: ?"
  --   local mem_usage = "RAM: ?"
  --   local function split_string(str, sep)
  --       local parts = {}
  --       for part in string.gmatch(str, "([^" .. sep .. "]+)") do
  --           table.insert(parts, part)
  --       end
  --       return parts
  --   end
  --   if success then
  --       local cleaned = stdout:gsub("\n", "")
  --       local parts = split_string(cleaned, "|")
  --       if #parts == 2 then
  --           cpu_usage = "CPU: " .. parts[1]
  --           mem_usage = "RAM: " .. parts[2]
  --       end
  --   end

  window:set_right_status(wezterm.format({
    { Background = { Color = "#0b0022" } },
    { Foreground = { Color = "#c0c0c0" } },
    {
      Text = string.format(
        "[%s] [%s] [%s] [%s] %s   ",
        workspace_name,
        battery,
        date,
        time,
        wezterm.nerdfonts.dev_apple
      ),
    },
  }))
end)

return config
