-- # conform.nvim
--
-- Formatting utility with support for non-LSP formatters.
-- More efficient than most formatters thanks to automatic diffing.
-- Falls back on LSP formatting.

vim.pack.add({ 'https://github.com/stevearc/conform.nvim' })

local ignore_filetypes = {}
local ignore_paths = {
  '/node_modules/',
  '/venv',
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

require('conform').setup({
  formatters_by_ft = {
    lua = { 'stylua' },
    python = {
      'ruff_format',
      'ruff_fix',
      'ruff_organize_imports',
      stop_after_first = false,
    },
    rust = { 'rustfmt' },
    toml = { 'taplo' },
    sh = { 'shellcheck', 'shfmt' },
    markdown = { 'rumdl', 'injected' },
  },
  default_format_opts = {
    lsp_format = 'fallback',
  },
  format_on_save = format_on_save,
})

vim.api.nvim_create_user_command('FormatDisable', function(opts)
  if opts.bang then
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
  vim.notify('Autoformat disabled' .. (opts.bang and ' (buffer)' or ' (global)'), vim.log.levels.WARN)
end, { desc = 'Disable autoformat-on-save', bang = true })

vim.api.nvim_create_user_command('FormatEnable', function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
  vim.notify('Autoformat enabled', vim.log.levels.INFO)
end, { desc = 'Re-enable autoformat-on-save' })

local auto_format = true

local map = vim.keymap.set

map('n', '<leader>uf', function()
  auto_format = not auto_format
  if auto_format then
    vim.cmd('FormatEnable')
  else
    vim.cmd('FormatDisable')
  end
end, { desc = 'Toggle Autoformat' })

map({ 'n', 'v' }, '<leader>cn', '<cmd>ConformInfo<cr>', { desc = 'Conform Info' })

map({ 'n', 'v' }, '<leader>cf', function()
  require('conform').format({ async = true }, function(err, did_edit)
    if not err and did_edit then
      vim.notify('Code formatted', vim.log.levels.INFO, { title = 'Conform' })
    end
  end)
end, { desc = 'Format buffer' })

map({ 'n', 'v' }, '<leader>cF', function()
  require('conform').format({ formatters = { 'injected' }, timeout_ms = 3000 })
end, { desc = 'Format Injected Langs' })
