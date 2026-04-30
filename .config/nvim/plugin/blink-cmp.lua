vim.pack.add({
  'https://github.com/saghen/blink.lib',
  'https://github.com/saghen/blink.cmp',
})

local _ = require('blink.lib')
local cmp = require('blink.cmp')

cmp.build():wait(60000)

cmp.setup({
  keymap = {
    preset = 'default',
    ['<C-e>'] = { 'show', 'hide' },
  },

  signature = {
    enabled = true,
    window = { show_documentation = false },
  },

  completion = {
    ghost_text = { enabled = true },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 1000,
    },
  },
})
