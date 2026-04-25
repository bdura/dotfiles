-- # Neovim options
--
-- Inspirations:
--
-- - https://tduyng.com/blog/neovim-basic-setup/
-- - https://github.com/vieitesss/nvim

local opt = vim.opt

-- Numbering & basic navigation
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.wrap = false
opt.linebreak = true
opt.scrolloff = 10
opt.sidescrolloff = 8

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

-- Search settings
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Visual settings
opt.termguicolors = true
opt.signcolumn = 'yes'
opt.completeopt = 'menu,menuone,noselect'

opt.list = true
opt.listchars = {
  -- NOTE
  tab = '» ',
  trail = '·',
  nbsp = '␣',
  lead = ' ',
  multispace = '·',
}
opt.fillchars = {
  eob = ' ',
}

-- File handling
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.undolevels = 10000
opt.autoread = true
opt.autowrite = false

-- Misc
opt.clipboard = vim.env.SSH_TTY and '' or 'unnamedplus'
