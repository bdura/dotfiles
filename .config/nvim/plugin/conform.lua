-- # conform.nvim
--
-- Formatting utility with support for non-LSP formatters.
-- More efficient than most formatters thanks to automatic diffing.
-- Falls back on LSP formatting.

vim.pack.add({ 'https://github.com/stevearc/conform.nvim' })

local ignore_filetypes = {}
local ignore_paths = {
  '/node_modules/',
  '/.venv/',
  '/target/',
}

---@param bufnr integer
local function format_on_save(bufnr)
  if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
    return
  end
  if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
    return
  end
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  for _, pattern in ipairs(ignore_paths) do
    if bufname:match(pattern) then
      return
    end
  end
  return { timeout_ms = 500, lsp_format = 'fallback' }
end

local conform = require('conform')

conform.setup({
  formatters = {
    yamlfmt = {
      command = 'yamlfmt',
      args = { '-formatter', 'retain_line_breaks_single=true', '-' },
    },
  },
  formatters_by_ft = {
    json = { 'jq' },
    kdl = { 'kdlfmt' },
    lua = { 'stylua' },
    markdown = { 'rumdl' },
    nix = { 'alejandra' },
    python = {
      'ruff_format',
      'ruff_fix',
      'ruff_organize_imports',
      stop_after_first = false,
    },
    rust = { 'rustfmt' },
    sh = { 'shellcheck', 'shfmt' },
    toml = { 'taplo' },
    typescript = { 'prettier' },
    yaml = { 'yamlfmt' },
    ['*'] = { 'injected' },
  },
  default_format_opts = {
    lsp_format = 'fallback',
  },
  format_on_save = format_on_save,
})

local map = vim.keymap.set

map({ 'n', 'v' }, '<leader>cn', '<cmd>ConformInfo<cr>', { desc = 'Conform Info' })
map({ 'n', 'v' }, '<leader>cf', function()
  conform.format({ async = true }, function(err, did_edit)
    if not err and did_edit then
      vim.notify('Code formatted', vim.log.levels.INFO, { title = 'Conform' })
    end
  end)
end, { desc = 'Format buffer' })
map({ 'n', 'v' }, '<leader>cF', function()
  conform.format({ formatters = { 'injected' }, timeout_ms = 3000 })
end, { desc = 'Format Injected Langs' })
