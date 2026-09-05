---@brief
--- https://codeberg.org/microcad/microcad/src/branch/main/crates/lsp
---
--- An LSP for the µcad model description language

---@type vim.lsp.Config
return {
  name = 'microcad-ls',
  cmd = { 'microcad-lsp', '--stdio' },
  filetypes = { 'microcad' },
  root_markers = { '.git' },
}
