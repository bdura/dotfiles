local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Package management
map('n', '<leader>Pu', vim.pack.update)

-- "Hot" reloading
map('n', '<leader>xf', '<cmd>source %<cr>', { desc = 'Source file' })
map('n', '<leader>xx', ':.lua<cr>', { desc = 'Source line' })
map('v', '<leader>xx', ':lua<cr>', { desc = 'Source selection' })

map({ 'i', 'x', 'n', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save File' })

-- Exit match highlighting on Esc
map('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Avoid copying on paste: visual-mode P preserves the unnamed register.
map('x', 'p', 'P', { desc = 'Paste without yanking selection' })
map('x', 'P', 'p', { desc = 'Paste and yank selection' })

-- Better indenting
map({ 'n', 'v' }, '>', '>gv')
map({ 'n', 'v' }, '<', '<gv')

-- Smart j/k: moves by visual lines when no count, real lines with count
map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
map({ 'n', 'x' }, '<Down>', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })
map({ 'n', 'x' }, '<Up>', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })

-- Center page navigation: scroll by a third of the window (a count passed to
-- <C-d>/<C-u> overrides the default half-page 'scroll' amount), then recenter.
local function scroll_third(key)
  return function()
    local third = math.max(1, math.floor(vim.api.nvim_win_get_height(0) / 3))
    return third .. key .. 'zz'
  end
end
map('n', '<C-d>', scroll_third('<C-d>'), { expr = true })
map('n', '<C-u>', scroll_third('<C-u>'), { expr = true })

-- Remove conflicting default keymaps
local del = vim.keymap.del
local keymaps = {
  'gri',
  'grn',
  'grr',
  'grt',
  'grx',
  'gO',
}
for _, keymap in ipairs(keymaps) do
  del('n', keymap)
end
del({ 'n', 'v' }, 'gra')
