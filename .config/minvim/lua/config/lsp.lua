vim.lsp.enable({
  -- Rust
  'rust-analyzer',
  -- Lua
  'lua-language-server',
  -- Python
  'ty',
  'ruff',
  -- Markdown
  'rumdl',
  -- Nix
  'nixd',
  -- WGSL & WESL
  'wgsl-analyzer'
})

local map = vim.keymap.set

map('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code Actions' })
map('n', '<leader>cr', vim.lsp.buf.rename, { desc = 'Code Rename' })
map('n', 'K', vim.lsp.buf.hover, { desc = 'Hover)' })
map('n', 'gd', vim.lsp.buf.definition, { desc = 'Goto Definition' })

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
