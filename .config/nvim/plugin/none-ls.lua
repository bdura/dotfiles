-- # none-ls
--
-- Plugs LSP capabilities from linters, formatters, etc.

vim.pack.add({
  'https://github.com/nvimtools/none-ls.nvim',
  'https://github.com/nvim-lua/plenary.nvim',
})

local null_ls = require('null-ls')

null_ls.setup({
  sources = {
    null_ls.builtins.diagnostics.hadolint,
  },
})
