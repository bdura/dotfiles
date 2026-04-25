vim.pack.add({
  'https://github.com/swaits/zellij-nav.nvim',
})

require('zellij-nav').setup()

local map = vim.keymap.set

map('n', '<c-h>', '<cmd>ZellijNavigateLeft<cr>', { silent = true, desc = 'navigate left or tab' })
map('n', '<c-j>', '<cmd>ZellijNavigateDown<cr>', { silent = true, desc = 'navigate down' })
map('n', '<c-k>', '<cmd>ZellijNavigateUp<cr>', { silent = true, desc = 'navigate up' })
map('n', '<c-l>', '<cmd>ZellijNavigateRight<cr>', { silent = true, desc = 'navigate right or tab' })
