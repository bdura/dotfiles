local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Package management
map('n', '<leader>Pu', vim.pack.update)

-- "Hot" reloading
map('n', '<leader><leader>x', '<cmd>source %<cr>')
map('n', '<leader>x', ':.lua<cr>')
map('v', '<leader>x', ':lua<cr>')

map({ 'i', 'x', 'n', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save File' })

-- Exit match highlighting on Esc
map('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Avoid copying on paste
map('v', 'p', '"_dP', opts)

-- Better indenting
map({ 'n', 'v' }, '>', '>gv')
map({ 'n', 'v' }, '<', '<gv')

-- Smart j/k: moves by visual lines when no count, real lines with count
map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
map({ 'n', 'x' }, '<Down>', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })
map({ 'n', 'x' }, '<Up>', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })

-- Center page navigation
map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')

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
