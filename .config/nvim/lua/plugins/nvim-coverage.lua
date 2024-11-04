return {
  'andythigpen/nvim-coverage',
  requires = 'nvim-lua/plenary.nvim',
  keys = {
    { '<leader>cc', '<cmd>Coverage<cr>', desc = 'Toggle Coverage' },
    { '<leader>cC', '<cmd>CoverageSummary<cr>', desc = 'Show coverage summary' },
  },
  opts = {},
}
