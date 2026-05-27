---@param short_direction 'h'|'j'|'k'|'l' Direction
---@param action 'move-focus'|'move-focus-or-tab'|nil Action to defer to zellij
---@param force boolean Whether to try to move within nvim first
local function nav(short_direction, direction, action, force)
  -- Use "move-focus" if action is nil.
  if not action then
    action = 'move-focus'
  end

  if action ~= 'move-focus' and action ~= 'move-focus-or-tab' then
    error('invalid action: ' .. action)
  end

  if force then
    vim.fn.system('zellij action ' .. action .. ' ' .. direction)
    return
  end

  -- get window ID, try switching windows, and get ID again to see if it worked
  local cur_winnr = vim.fn.winnr()
  vim.api.nvim_command('wincmd ' .. short_direction)
  local new_winnr = vim.fn.winnr()

  -- if the window ID didn't change, then we didn't switch
  if cur_winnr == new_winnr then
    vim.fn.system('zellij action ' .. action .. ' ' .. direction)
    if vim.v.shell_error ~= 0 then
      error('zellij executable not found in path')
    end
  end
end

---@param force boolean
---@return function()
local function up(force)
  return function()
    nav('k', 'up', nil, force)
  end
end

---@param force boolean
---@return function()
local function down(force)
  return function()
    nav('j', 'down', nil, force)
  end
end

---@param force boolean
---@return function()
local function left(force)
  return function()
    nav('h', 'left', nil, force)
  end
end

---@param force boolean
---@return function()
local function right(force)
  return function()
    nav('l', 'right', nil, force)
  end
end

-- local function up_tab()
--   nav("k", "up", "move-focus-or-tab")
-- end

local map = vim.keymap.set

map({ 'n', 'i', 'v' }, '<C-h>', left(false), { silent = true, desc = 'Navigate left' })
map({ 'n', 'i', 'v' }, '<C-j>', down(false), { silent = true, desc = 'Navigate down' })
map({ 'n', 'i', 'v' }, '<C-k>', up(false), { silent = true, desc = 'Navigate up' })
map({ 'n', 'i', 'v' }, '<C-l>', right(false), { silent = true, desc = 'Navigate right' })

map('t', '<C-h>', left(true), { silent = true, desc = 'Navigate left' })
map('t', '<C-j>', down(true), { silent = true, desc = 'Navigate down' })
map('t', '<C-k>', up(true), { silent = true, desc = 'Navigate up' })
map('t', '<C-l>', right(true), { silent = true, desc = 'Navigate right' })
