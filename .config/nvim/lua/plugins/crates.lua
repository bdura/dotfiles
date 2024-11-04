-- `crates.nvim` checks the `Cargo.toml` file for outdated dependencies.
return {
  'Saecki/crates.nvim',
  event = { 'BufRead Cargo.toml' },
  opts = {
    completion = {
      crates = {
        enabled = true,
      },
    },
    lsp = {
      enabled = true,
      actions = true,
      completion = true,
      hover = true,
    },
  },
}
