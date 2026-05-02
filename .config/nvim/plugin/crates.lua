vim.pack.add({
  'https://github.com/saecki/crates.nvim',
})

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

local group = augroup('CratesSetup', { clear = true })

-- Highlight when yanking (copying) text
autocmd('BufRead', {
  pattern = 'Cargo.toml',
  desc = 'Setup crates.nvim',
  group = group,
  callback = function()
    require('crates').setup({
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    })
  end,
})
