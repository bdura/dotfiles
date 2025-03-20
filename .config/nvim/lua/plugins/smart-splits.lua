-- The smart-splits plugin enables seamless navigation between
-- Nvim and Wezterm using the `<C-h/j/k/l>` keys
--
-- It also adds resize capabilities with the `<A-h/j/k/l>` keys
return {
  'mrjones2014/smart-splits.nvim',
  lazy = false,
  keys = {
    {
      '<A-h>',
      mode = { 'n' },
      function()
        require('smart-splits').resize_left()
      end,
      desc = 'Resize pane left',
    },
    {
      '<A-j>',
      mode = { 'n' },
      function()
        require('smart-splits').resize_down()
      end,
      desc = 'Resize pane down',
    },
    {
      '<A-k>',
      mode = { 'n' },
      function()
        require('smart-splits').resize_up()
      end,
      desc = 'Resize pane up',
    },
    {
      '<A-l>',
      mode = { 'n' },
      function()
        require('smart-splits').resize_right()
      end,
      desc = 'Resize pane right',
    },
    {
      '<C-h>',
      mode = { 'n' },
      function()
        require('smart-splits').move_cursor_left()
      end,
      desc = 'Move to left pane',
    },
    {
      '<C-j>',
      mode = { 'n' },
      function()
        require('smart-splits').move_cursor_down()
      end,
      desc = 'Move to bottom pane',
    },
    {
      '<C-k>',
      mode = { 'n' },
      function()
        require('smart-splits').move_cursor_up()
      end,
      desc = 'Move to top pane',
    },
    {
      '<C-l>',
      mode = { 'n' },
      function()
        require('smart-splits').move_cursor_right()
      end,
      desc = 'Move to right pane',
    },
    --
    -- The following keys are conflicting with other shortcuts,
    -- but still propose nice additions.
    --
    -- I'd like to explore these in the near future
    --
    -- {
    --   '<C-\\>',
    --   mode = { 'n' },
    --   function()
    --     require('smart-splits').move_cursor_previous()
    --   end,
    -- },
    -- {
    --   '<leader><leader>h',
    --   mode = { 'n' },
    --   function()
    --     require('smart-splits').swap_buf_left()
    --   end,
    -- },
    -- {
    --   '<leader><leader>j',
    --   mode = { 'n' },
    --   function()
    --     require('smart-splits').swap_buf_down()
    --   end,
    -- },
    -- {
    --   '<leader><leader>k',
    --   mode = { 'n' },
    --   function()
    --     require('smart-splits').swap_buf_up()
    --   end,
    -- },
    -- {
    --   '<leader><leader>l',
    --   mode = { 'n' },
    --   function()
    --     require('smart-splits').swap_buf_right()
    --   end,
    -- },
  },
}
