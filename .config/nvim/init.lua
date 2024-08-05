-- Top-level configuration for neovim.

-- General options and remaps (eg leader key)
require('config.options')

-- Keymaps
require('config.keymaps')

-- Bootstrap Lazy
require('config.lazy')

-- Choose colorscheme
vim.cmd.colorscheme('tokyonight')
