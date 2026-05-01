vim.pack.add({
  -- Core
  'https://codeberg.org/mfussenegger/nvim-dap',
  -- UI
  'https://github.com/igorlfs/nvim-dap-view',
  -- Language-specific
  'https://codeberg.org/mfussenegger/nvim-dap-python',
})

local dap = require('dap')
local dap_view = require('dap-view')
local dap_python = require('dap-python')

dap_python.setup('python')
dap_view.setup({})

vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
vim.fn.sign_define(
  'DapBreakpointCondition',
  { text = '●', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' }
)

vim.api.nvim_set_hl(0, 'DapBreakpoint', { link = 'ErrorMsg' })
vim.api.nvim_set_hl(0, 'DapBreakpointCondition', { link = 'WarningMsg' })
vim.api.nvim_set_hl(0, 'DapLogPoint', { link = 'Special' })
vim.api.nvim_set_hl(0, 'DapStoppedLine', { link = 'Visual' })
vim.api.nvim_set_hl(0, 'DapBreakpointLine', { link = 'DapBreakpoint' })

local function breakpoint_condition()
  dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
end

local function show_breakpoint_condition()
  local breakpoints = require('dap.breakpoints')
  local line = vim.fn.line('.')
  local buf = vim.api.nvim_get_current_buf()

  ---@type dap.bp[]
  local bps = breakpoints.get()[buf]

  for _, bp in ipairs(bps) do
    if bp.line == line and bp.buf == buf then
      if bp.condition then
        vim.notify('Condition:\n`' .. bp.condition .. '`', vim.log.levels.INFO)
      else
        vim.notify('No condition on this breakpoint', vim.log.levels.WARN)
      end
      return
    end
  end
  vim.notify('No breakpoint on this line', vim.log.levels.WARN)
end

local map = vim.keymap.set

map('n', '<leader>dB', breakpoint_condition, { desc = 'Breakpoint Condition' })
map('n', '<leader>dL', show_breakpoint_condition, { desc = 'Show Breakpoint Condition' })
map('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Toggle Breakpoint' })
map('n', '<leader>dc', dap.continue, { desc = 'Run/Continue' })
map('n', '<leader>dC', dap.run_to_cursor, { desc = 'Run to Cursor' })
map('n', '<leader>dg', dap.goto_, { desc = 'Go to Line (No Execute)' })
map('n', '<leader>di', dap.step_into, { desc = 'Step Into' })
map('n', '<leader>dj', dap.down, { desc = 'Down' })
map('n', '<leader>dk', dap.up, { desc = 'Up' })
map('n', '<leader>dl', dap.run_last, { desc = 'Run Last' })
map('n', '<leader>do', dap.step_out, { desc = 'Step Out' })
map('n', '<leader>dO', dap.step_over, { desc = 'Step Over' })
map('n', '<leader>dP', dap.pause, { desc = 'Pause' })
map('n', '<leader>dr', dap.repl.toggle, { desc = 'Toggle REPL' })
map('n', '<leader>ds', dap.session, { desc = 'Session' })
map('n', '<leader>ds', dap.session, { desc = 'Session' })
map({ 'n', 'v' }, '<leader>dK', dap_view.hover, { desc = 'Hover' })
map({ 'n', 'v' }, '<leader>dv', dap_view.toggle, { desc = 'Toggle Dap View' })
