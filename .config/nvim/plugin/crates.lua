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

-- After saving Cargo.toml, run `cargo check` in the background so the lockfile
-- stays in sync with manifest changes.
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = 'Cargo.toml',
  desc = 'Update Cargo.lock after saving Cargo.toml',
  group = vim.api.nvim_create_augroup('CratesLockfileUpdate', { clear = true }),
  callback = function(args)
    local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(args.buf))
    local handle = require('fidget.progress').handle.create({
      title = 'cargo check',
      message = 'running…',
      lsp_client = { name = 'crates.nvim' },
    })
    vim.system({ 'cargo', 'check', '--quiet' }, { cwd = dir }, function(result)
      -- NOTE: vim.system callbacks run on a libuv thread, so we need
      -- vim.schedule to safely call fidget on the main loop.
      vim.schedule(function()
        if result.code == 0 then
          handle.message = 'done'
          handle:finish()
        else
          handle.message = 'failed'
          handle:cancel()
          vim.notify('cargo check failed:\n' .. (result.stderr or ''), vim.log.levels.WARN)
        end
      end)
    end)
  end,
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
