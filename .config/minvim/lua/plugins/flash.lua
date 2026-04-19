vim.pack.add({
  "https://github.com/folke/flash.nvim",
})

require("flash").setup({
    modes = {
      search = {
        enabled = true,
      },
      char = {
        jump_labels = true,
      },
    },
})

local flash_lines = function()
  require('flash').jump({
    search = { mode = 'search', max_length = 0 },
    label = { after = { 0, 0 } },
    pattern = '^',
  })
end

local map = vim.keymap.set

map({ "n", "x", "o" }, "s", function() require("flash").jump() end, {desc = "Flash" })
map({ "n", "o", "x" }, "S", function() require("flash").treesitter() end, {desc = "Flash Treesitter" })
map( "o", "r", function() require("flash").remote() end, {desc = "Flash Treesitter" })
map( {"o", "x"}, "R", function() require("flash").treesitter_search() end, {desc = "Treesitter Search" })
map( { "n", "v", "o" },"<leader>j", flash_lines, {desc = "Flash lines" })

vim.keymap.set({"n", "x", "o"}, "<c-space>", function()
  require("flash").treesitter({
    actions = {
      ["<c-space>"] = "next",
      ["<BS>"] = "prev"
    }
  })
end, { desc = "Treesitter incremental selection" })
