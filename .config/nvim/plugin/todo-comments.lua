vim.pack.add({
  'https://github.com/folke/todo-comments.nvim',
  'https://github.com/nvim-lua/plenary.nvim',
})

require('todo-comments').setup({
  keywords = {
    FIX = {
      icon = ' ',
      color = 'error',
      alt = { 'FIXME', 'BUG', 'FIXIT', 'ISSUE' },
    },
    TODO = { icon = ' ', color = 'info' },
    HACK = { icon = ' ', color = 'warning' },
    WARN = { icon = ' ', color = 'warning', alt = { 'WARNING', 'XXX' } },
    PERF = { icon = ' ', alt = { 'OPTIM', 'PERFORMANCE', 'OPTIMIZE' } },
    NOTE = { icon = ' ', color = 'hint', alt = { 'INFO' } },
    TEST = { icon = '⏲ ', color = 'test', alt = { 'TESTING', 'PASSED', 'FAILED' } },
    SAFETY = { icon = ' ', color = 'info' },
    UNSAFE = { icon = ' ', color = 'warning' },
    QUESTION = { icon = ' ', color = 'warning' },
  },
  colors = {
    error = { 'DiagnosticError', 'ErrorMsg' },
    warning = { 'DiagnosticWarn', 'WarningMsg' },
    info = { 'DiagnosticInfo' },
    hint = { 'DiagnosticHint' },
    default = { 'Identifier' },
    test = { 'Identifier' },
  },
})
