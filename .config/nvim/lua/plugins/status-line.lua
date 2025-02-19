-- Still not sure about this but I tend to prefer Mini's implementation.
-- It looks like the lualine implementation is packed with more information,
-- but I'm fine with that for now.

return {
  {
    'nvim-lualine/lualine.nvim',
    enabled = false,
  },
  { 'echasnovski/mini.statusline', version = '*', opts = {} },
}
