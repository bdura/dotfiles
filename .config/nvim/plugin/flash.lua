vim.pack.add({
  'https://github.com/folke/flash.nvim',
})

local flash = require('flash')

flash.setup({
  modes = {
    search = {
      enabled = true,
    },
    char = {
      jump_labels = true,
    },
  },
})

local flash_words = function()
  flash.jump({
    pattern = '.', -- initialize pattern with any char
    search = {
      mode = function(pattern)
        -- remove leading dot
        if pattern:sub(1, 1) == '.' then
          pattern = pattern:sub(2)
        end
        -- return word pattern and proper skip pattern
        return ([[\<%s\w*\>]]):format(pattern), ([[\<%s]]):format(pattern)
      end,
    },
    -- select the range
    jump = { pos = 'range' },
  })
end

local flash_lines = function(forward)
  return function()
    flash.jump({
      search = { mode = 'search', max_length = 0, forward = forward, wrap = false },
      label = { after = { 0, 0 } },
      pattern = '^',
    })
  end
end

local map = vim.keymap.set

map({ 'n', 'x', 'o' }, 's', flash.jump, { desc = 'Flash' })
map({ 'n', 'o', 'x' }, 'S', flash.treesitter, { desc = 'Flash Treesitter' })
map('o', 'r', flash.remote, { desc = 'Flash Treesitter' })
map({ 'o', 'x' }, 'R', flash.treesitter_search, { desc = 'Treesitter Search' })
map({ 'n', 'v', 'o' }, '<leader>j', flash_lines(true), { desc = 'Flash lines below' })
map({ 'n', 'v', 'o' }, '<leader>k', flash_lines(false), { desc = 'Flash lines above' })
map('n', '<leader>w', flash_words, { desc = 'Flash words' })

vim.keymap.set({ 'n', 'x', 'o' }, '<c-enter>', function()
  flash.treesitter({
    actions = {
      ['<c-enter>'] = 'next',
      ['<BS>'] = 'prev',
    },
  })
end, { desc = 'Treesitter incremental selection' })
