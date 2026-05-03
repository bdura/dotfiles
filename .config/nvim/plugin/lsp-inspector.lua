require('plugins.lsp-inspector').setup()

---@param buffer_only boolean
---@return fun()
local function show(buffer_only)
  return function()
    require('plugins.lsp-inspector').show_lsp_matrix({ buffer_only = buffer_only })
  end
end

vim.keymap.set('n', '<leader>ci', show(false), { desc = 'Global LSP inspector' })
vim.keymap.set('n', '<leader>cI', show(true), { desc = 'Local LSP inspector' })
