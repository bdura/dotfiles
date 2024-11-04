return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    view_options = { show_hidden = true },
  },
  -- Optional dependencies
  -- dependencies = { { 'echasnovski/mini.icons', opts = {} } },
  dependencies = { 'nvim-tree/nvim-web-devicons' }, -- use if prefer nvim-web-devicons
  config = function()
    local oil = require('oil')
    oil.setup()
    vim.keymap.set('n', '-', oil.toggle_float, {})
  end,
}
