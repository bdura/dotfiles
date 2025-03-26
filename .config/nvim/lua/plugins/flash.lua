local flash_lines = function()
  require('flash').jump({
    search = { mode = 'search', max_length = 0 },
    label = { after = { 0, 0 } },
    pattern = '^',
  })
end

return {
  'folke/flash.nvim',
  event = 'VeryLazy',
  vscode = true,
  ---@type Flash.Config
  opts = {
    modes = {
      char = {
        jump_labels = true,
      },
    },
    label = {
      rainbow = {
        enabled = true,
        -- number between 1 and 9
        shade = 3,
      },
    },
  },
  -- stylua: ignore
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    { "<leader>j", mode = { "n", "v", "o" }, flash_lines, desc = "Flash lines" },
    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
  },
}
