---@type vim.lsp.Config
return {
  cmd = { 'docker-langserver', '--stdio' },
  filetypes = { 'dockerfile' },
  root_markers = { 'Dockerfile' },
  on_attach = function(client, _)
    -- NOTE: the semantic tokens provided by docker-langserver
    -- remove syntax highlighting for bash scripting...
    client.server_capabilities.semanticTokensProvider = nil
  end,
}
