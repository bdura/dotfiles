vim.pack.add({
  'https://github.com/stevearc/oil.nvim',
  'https://github.com/nvim-mini/mini.icons',
})

require('mini.icons').setup({})

local oil = require('oil')
local hidden = {
  '..',
  '.git',
  '.ipynb_checkpoints',
  '.DS_Store',
  '.ruff_cache',
  '.pytest_cache',
  '.venv',
}

oil.setup({
  view_options = {
    show_hidden = true,
    is_always_hidden = function(name, _)
      for _, n in ipairs(hidden) do
        if n == name then
          return true
        end
      end
      return false
    end,
  },
  watch_for_changes = true,
  keymaps = {
    ['q'] = { callback = 'actions.close', mode = 'n' },
  },
})
vim.keymap.set('n', '-', oil.toggle_float, {})
