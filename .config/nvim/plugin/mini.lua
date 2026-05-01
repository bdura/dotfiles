vim.pack.add({
  'https://github.com/nvim-mini/mini.nvim',
})

-- # Icons
local icons = require('mini.icons')
-- WESL icons
local glyph = '󰬄'
local hl = 'MiniIconsBlue'
icons.setup({
  filetype = { wesl = { glyph = glyph, hl = hl } },
  extension = { wesl = { glyph = glyph, hl = hl } },
})

-- # Status line
require('mini.statusline').setup()

-- # Auto-pairing
require('mini.pairs').setup({
  modes = { insert = true, command = true, terminal = false },
  -- skip autopair when next character is one of these
  skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
  -- skip autopair when the cursor is inside these treesitter nodes
  skip_ts = { 'string' },
  -- skip autopair when next character is closing pair
  -- and there are more closing pairs than opening pairs
  skip_unbalanced = true,
  -- better deal with markdown code blocks
  markdown = true,
})
