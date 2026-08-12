---@brief
---
--- https://github.com/crate-ci/typos
--- https://github.com/tekumara/typos-lsp
---
--- A Language Server Protocol implementation for Typos, a low false-positive
--- source code spell checker, written in Rust.

---@type vim.lsp.Config
return {
  cmd = { 'typos-lsp' },
  root_markers = { 'typos.toml', '_typos.toml', '.typos.toml', 'uv.lock', 'Cargo.lock' },
  settings = {},
}
