-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local set = vim.opt

set.list = true
set.listchars = { tab = '» ', trail = '·', nbsp = '␣', lead = '·', multispace = '·' }

vim.lsp.config['confit-lsp'] = {
  -- Command and arguments to start the server.
  cmd = { 'confit-lsp' },
  -- Filetypes to automatically attach to.
  filetypes = { 'toml' },
  -- Sets the "workspace" to the directory where any of these files is found.
  -- Files that share a root directory will reuse the LSP server connection.
  -- Nested lists indicate equal priority, see |vim.lsp.Config|.
  root_markers = { { 'pyproject.toml' }, '.git' },
  -- Specific settings to send to the server. The schema is server-defined.
  -- Example: https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json
}

vim.highlight.priorities.semantic_tokens = 95

-- vim.lsp.enable('ty')
-- vim.diagnostic.config({ virtual_lines = { current_line = true } })
