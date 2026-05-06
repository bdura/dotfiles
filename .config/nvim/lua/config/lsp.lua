vim.lsp.enable({
  -- Rust
  'rust-analyzer',
  -- Lua
  'lua_ls',
  -- Python
  'ty',
  'ruff',
  -- Markdown
  'rumdl',
  -- Nix
  'nixd',
  -- WGSL & WESL
  'wgsl-analyzer',
  -- TOML
  'taplo',
  -- YAML
  'yaml-ls',
  -- OpenSCAD
  'openscad',
  -- Docker
  -- NOTE: docker-ls would be the preferred option since it's compiled...
  -- But it does not work with dockerfiles and gives worse information
  -- than yaml-ls for docker-compose files...
  -- 'docker-ls',
  'dockerfile-ls',
  -- TypeScript
  'typescript-ls',
  -- Bash
  'bash-ls',
})

local map = vim.keymap.set

map('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code Actions' })
map('n', '<leader>cr', vim.lsp.buf.rename, { desc = 'Code Rename' })
map('n', 'K', vim.lsp.buf.hover, { desc = 'Hover)' })

vim.api.nvim_create_autocmd('LspProgress', {
  pattern = 'end',
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or not client:supports_method('textDocument/inlayHint') then
      return
    end
    for bufnr in pairs(client.attached_buffers) do
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end
  end,
})

-- Cycle: hybrid -> text -> lines -> hybrid
local diagnostic_modes = { 'hybrid', 'text', 'lines' }
local diagnostic_mode_index = 1

local diagnostic_configs = {
  hybrid = { virtual_text = { current_line = false }, virtual_lines = { current_line = true } },
  text = { virtual_text = true, virtual_lines = false },
  lines = { virtual_text = false, virtual_lines = true },
}

local function apply_diagnostic_config()
  local mode = diagnostic_modes[diagnostic_mode_index]
  vim.diagnostic.config(diagnostic_configs[mode])
end

apply_diagnostic_config()

map('n', '<leader>cv', function()
  diagnostic_mode_index = diagnostic_mode_index % #diagnostic_modes + 1
  apply_diagnostic_config()
  local mode = diagnostic_modes[diagnostic_mode_index]
  vim.notify('Diagnostics: ' .. mode)
end, { desc = 'Cycle diagnostic display' })
