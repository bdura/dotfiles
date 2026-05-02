return {
  cmd = { 'taplo', 'lsp', 'stdio' },
  filetypes = { 'toml' },
  root_markers = { '.taplo.toml', 'taplo.toml', '.git' },
  settings = {
    evenBetterToml = {
      schema = {
        enabled = true,
        catalogs = { 'https://www.schemastore.org/api/json/catalog.json' },
        cache = {
          memoryExpiration = 60,
          diskExpiration = 600,
        },
        associations = {
          ['.*/Cargo\\.toml$'] = 'https://json.schemastore.org/cargo.json',
          ['.*/pyproject\\.toml$'] = 'https://json.schemastore.org/pyproject.json',
          ['.*/\\.?rustfmt\\.toml$'] = 'https://json.schemastore.org/rustfmt.json',
          ['.*/rust-toolchain\\.toml$'] = 'https://json.schemastore.org/rust-toolchain.json',
          ['.*/\\.?taplo\\.toml$'] = 'https://taplo.tamasfe.dev/schemas/v1/config.json',
          ['.*/uv\\.toml$'] = 'https://json.schemastore.org/uv.json',
          ['.*/\\.?ruff\\.toml$'] = 'https://json.schemastore.org/ruff.json',
        },
      },
    },
  },
}
