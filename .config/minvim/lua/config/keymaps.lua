local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Package management
map('n', '<leader>Pu', '<cmd>lua vim.pack.update()<CR>')

-- "Hot" reloading
map('n', '<leader><leader>x', '<cmd>source %<cr>')
map('n', '<leader>x', ':.lua<cr>')
map('v', '<leader>x', ':lua<cr>')

map({ 'i', 'x', 'n', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save File' })

-- Exit match highlighting on Esc
map('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Avoid copying on paste
map('v', 'p', '"_dP', opts)

-- better indenting
map({ 'n', 'v' }, '>', '>gv')
map({ 'n', 'v' }, '<', '<gv')

-- Smart j/k: moves by visual lines when no count, real lines with count
map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
map({ 'n', 'x' }, '<Down>', "v:count == 0 ? 'gj' : 'j'", { desc = 'Down', expr = true, silent = true })
map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })
map({ 'n', 'x' }, '<Up>', "v:count == 0 ? 'gk' : 'k'", { desc = 'Up', expr = true, silent = true })

-- Move lines up/down
map('n', '<A-j>', "<cmd>execute 'move .+' . v:count1<cr>==", { desc = 'Move Down' })
map('n', '<A-k>', "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = 'Move Up' })
map('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move Down' })
map('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move Up' })
map('v', '<A-j>', ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = 'Move Down' })
map('v', '<A-k>', ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = 'Move Up' })
