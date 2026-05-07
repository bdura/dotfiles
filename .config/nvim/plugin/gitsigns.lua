vim.pack.add({ 'https://github.com/lewis6991/gitsigns.nvim' })

require('gitsigns').setup({ current_line_blame = true })
require('gitsigns').setup({
  current_line_blame = true,

  ---@param bufnr integer
  on_attach = function(bufnr)
    local gitsigns = require('gitsigns')

    ---@param mode string|string[]
    ---@param l string
    ---@param r fun()
    ---@param desc string
    local function map(mode, l, r, desc, opts)
      opts = opts or {}
      opts.buffer = bufnr
      opts.desc = desc
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation
    map('n', ']h', function()
      gitsigns.nav_hunk('next')
    end, 'Next hunk')

    map('n', '[h', function()
      gitsigns.nav_hunk('prev')
    end, 'Previous hunk')

    -- Actions
    map('n', '<leader>ghs', gitsigns.stage_hunk, 'Stage hunk')
    map('n', '<leader>ghr', gitsigns.reset_hunk, 'Reset hunk')

    map('v', '<leader>ghs', function()
      gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, 'Stage selection')

    map('v', '<leader>ghr', function()
      gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, 'Reset selection')

    map('n', '<leader>ghS', gitsigns.stage_buffer, 'Stage buffer')
    map('n', '<leader>ghR', gitsigns.reset_buffer, 'Reset buffer')
    map('n', '<leader>ghp', gitsigns.preview_hunk_inline, 'Preview hunk (inline)')
    map('n', '<leader>ghP', gitsigns.preview_hunk, 'Preview hunk (floating)')

    map('n', '<leader>ghQ', function()
      gitsigns.setqflist('all')
    end, 'Add all hunks to QuickFix')
    map('n', '<leader>ghq', gitsigns.setqflist, 'Add buffer hunks to QuickFix')

    -- Toggles
    map('n', '<leader>gb', gitsigns.toggle_current_line_blame, 'Toggle line blame')
    map('n', '<leader>gw', gitsigns.toggle_word_diff, 'Toggle word diff')

    -- Text object
    map({ 'o', 'x' }, 'ih', gitsigns.select_hunk, 'Select hunk')
  end,
})
