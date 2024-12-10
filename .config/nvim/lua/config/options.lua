-- Define leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

local set = vim.opt

-- Make line numbers default
set.number = true
set.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
set.mouse = 'a'

-- Don't show the mode, since it's already in the status line
set.showmode = false

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
set.clipboard = 'unnamedplus'

-- Enable break indent
set.breakindent = true

-- Save undo history
set.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
set.ignorecase = true
set.smartcase = true

-- Keep signcolumn on by default
set.signcolumn = 'yes'

-- Decrease update time
set.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
set.timeoutlen = 300

-- Configure how new splits should be opened
set.splitright = true
set.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
set.list = true
set.listchars = { tab = '» ', trail = '·', nbsp = '␣', lead = '·', multispace = '·' }

-- Preview substitutions live, as you type!
set.inccommand = 'split'

-- Show which line your cursor is on
set.cursorline = true

-- 4 space indenting by default
set.shiftwidth = 4

-- Minimal number of screen lines to keep above and below the cursor.
set.scrolloff = 10

-- Set highlight on search, but clear on pressing <Esc> in normal mode
set.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
