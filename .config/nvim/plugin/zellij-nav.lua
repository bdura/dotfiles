vim.pack.add({ 'https://github.com/swaits/zellij-nav.nvim' })

local zellij = require('zellij-nav')
zellij.setup()

local map = vim.keymap.set

map({ 'n', 'i', 'v' }, '<C-h>', zellij.left, { silent = true, desc = 'Navigate left' })
map({ 'n', 'i', 'v' }, '<C-j>', zellij.down, { silent = true, desc = 'Navigate down' })
map({ 'n', 'i', 'v' }, '<C-k>', zellij.up, { silent = true, desc = 'Navigate up' })
map({ 'n', 'i', 'v' }, '<C-l>', zellij.right, { silent = true, desc = 'Navigate right' })
