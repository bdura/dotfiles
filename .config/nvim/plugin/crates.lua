vim.pack.add({
  'https://github.com/saecki/crates.nvim',
})

local crates = require('crates')
crates.setup({
  lsp = {
    enabled = true,
    actions = true,
    completion = true,
    -- NOTE: setting hover hijacks the LSP capabilities for the entire buffer.
    -- Since we want to keep taplo working for attributes that are not
    -- crates.io-related, we disable hover and activate it in an autocmd directly
    -- (see below)
    hover = false,
  },
})

-- On Cargo.toml, rebind K so crates.nvim's popup wins when the cursor is on a
-- crate/version line, and the LSP hover (taplo) handles everything else.
vim.api.nvim_create_autocmd('BufRead', {
  pattern = 'Cargo.toml',
  desc = 'crates.nvim hover with LSP fallback',
  group = vim.api.nvim_create_augroup('CratesHover', { clear = true }),
  callback = function(args)
    vim.keymap.set('n', 'K', function()
      if crates.popup_available() then
        crates.show_popup()
      else
        vim.lsp.buf.hover()
      end
    end, { buffer = args.buf, desc = 'crates.nvim popup or LSP hover' })
  end,
})
