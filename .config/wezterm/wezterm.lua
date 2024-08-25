-- Taken from https://github.com/dragonlobster/wezterm-config
--
-- Pull in the wezterm API
local wezterm = require('wezterm')

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- For example, changing the color scheme:
config.color_scheme = 'tokyonight_night'
config.font = wezterm.font('JetBrainsMono Nerd Font')
config.font_size = 13

-- config.window_decorations = 'RESIZE'

-- tmux
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 2000 }
config.keys = {
  { key = 'V', mods = 'CTRL', action = wezterm.action.PasteFrom('Clipboard') },
  {
    mods = 'LEADER',
    key = 'c',
    action = wezterm.action.SpawnTab('CurrentPaneDomain'),
  },
  {
    mods = 'LEADER',
    key = 'x',
    action = wezterm.action.CloseCurrentPane({ confirm = false }),
  },
  {
    mods = 'LEADER',
    key = 'b',
    action = wezterm.action.ActivateTabRelative(-1),
  },
  {
    mods = 'LEADER',
    key = 'n',
    action = wezterm.action.ActivateTabRelative(1),
  },
  {
    mods = 'LEADER',
    key = '|',
    action = wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
  },
  {
    mods = 'LEADER',
    key = '-',
    action = wezterm.action.SplitVertical({ domain = 'CurrentPaneDomain' }),
  },
  {
    mods = 'LEADER',
    key = 'h',
    action = wezterm.action.ActivatePaneDirection('Left'),
  },
  {
    mods = 'LEADER',
    key = 'j',
    action = wezterm.action.ActivatePaneDirection('Down'),
  },
  {
    mods = 'LEADER',
    key = 'k',
    action = wezterm.action.ActivatePaneDirection('Up'),
  },
  {
    mods = 'LEADER',
    key = 'l',
    action = wezterm.action.ActivatePaneDirection('Right'),
  },
  {
    mods = 'LEADER',
    key = 'LeftArrow',
    action = wezterm.action.AdjustPaneSize({ 'Left', 5 }),
  },
  {
    mods = 'LEADER',
    key = 'RightArrow',
    action = wezterm.action.AdjustPaneSize({ 'Right', 5 }),
  },
  {
    mods = 'LEADER',
    key = 'DownArrow',
    action = wezterm.action.AdjustPaneSize({ 'Down', 5 }),
  },
  {
    mods = 'LEADER',
    key = 'UpArrow',
    action = wezterm.action.AdjustPaneSize({ 'Up', 5 }),
  },
}

for i = 1, 9 do
  -- leader + number to activate that tab
  table.insert(config.keys, {
    mods = 'LEADER',
    key = tostring(i),
    action = wezterm.action.ActivateTab(i - 1),
  })
end

-- tab bar
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = false
config.tab_and_split_indices_are_zero_based = false

-- tmux status
-- wezterm.on('update-right-status', function(window, _)
--   local SOLID_LEFT_ARROW = ''
--   local ARROW_FOREGROUND = { Foreground = { Color = 'fg' } }
--   local prefix = ''
--
--   if window:leader_is_active() then
--     prefix = ' 🌊'
--     SOLID_LEFT_ARROW = ''
--   end
--
--   if window:active_tab():tab_id() ~= 0 then
--     ARROW_FOREGROUND = { Foreground = { Color = 'blue1' } }
--   end -- arrow color based on if tab is first pane
--
--   window:set_left_status(wezterm.format({
--     { Background = { Color = '#b7bdf8' } },
--     { Text = prefix },
--     ARROW_FOREGROUND,
--     { Text = SOLID_LEFT_ARROW },
--   }))
-- end)

-- if you are *NOT* lazy-loading smart-splits.nvim (recommended)
local function is_vim(pane)
  -- this is set by the plugin, and unset on ExitPre in Neovim
  return pane:get_user_vars().IS_NVIM == 'true'
end

local direction_keys = {
  h = 'Left',
  j = 'Down',
  k = 'Up',
  l = 'Right',
}

local function move(key)
  return {
    key = key,
    mods = 'CTRL',
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        -- pass the keys through to vim/nvim
        win:perform_action({
          SendKey = { key = key, mods = 'CTRL' },
        }, pane)
      else
        win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
      end
    end),
  }
end

local function resize(key)
  return {
    key = key,
    mods = 'META',
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        -- pass the keys through to vim/nvim
        win:perform_action({
          SendKey = { key = key, mods = 'META' },
        }, pane)
      else
        win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
      end
    end),
  }
end

for key, _ in pairs(direction_keys) do
  table.insert(config.keys, move(key))
  table.insert(config.keys, resize(key))
end

-- and finally, return the configuration to wezterm
return config
