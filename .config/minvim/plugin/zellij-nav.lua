vim.pack.add({ 'https://github.com/swaits/zellij-nav.nvim' })

require('zellij-nav').setup()

local map = vim.keymap.set

map({ 'n', 'i', 'v' }, '<c-h>', '<cmd>ZellijNavigateLeft<cr>', { silent = true, desc = 'Navigate left' })
map({ 'n', 'i', 'v' }, '<c-j>', '<cmd>ZellijNavigateDown<cr>', { silent = true, desc = 'Navigate down' })
map({ 'n', 'i', 'v' }, '<c-k>', '<cmd>ZellijNavigateUp<cr>', { silent = true, desc = 'Navigate up' })
map({ 'n', 'i', 'v' }, '<c-l>', '<cmd>ZellijNavigateRight<cr>', { silent = true, desc = 'Navigate right' })
