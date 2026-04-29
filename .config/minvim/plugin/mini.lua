vim.pack.add({
  'https://github.com/nvim-mini/mini.nvim',
})

local icons = require('mini.icons')

-- WESL icons
local glyph = '󰬄'
local hl = 'MiniIconsBlue'

icons.setup({
  filetype  = { wesl = { glyph = glyph, hl = hl } },
  extension = { wesl = { glyph = glyph, hl = hl } },
})
-- icons.mock_nvim_web_devicons()

require('mini.statusline').setup()
