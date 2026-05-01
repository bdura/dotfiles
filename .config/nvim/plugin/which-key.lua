vim.pack.add({
  'https://github.com/folke/which-key.nvim',
})

local wk = require('which-key')

wk.setup({
  preset = 'helix',
})

wk.add({
  { '<leader>c', group = 'Code' },
  { ']', group = 'Next' },
  { '[', group = 'Previous' },
  { '<leader>d', group = 'Debugging' },
  { '<leader>b', group = 'Buffer Managment' },
})
