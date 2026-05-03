local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

local highlight_group = augroup('Highlight', { clear = true })

-- Highlight when yanking (copying) text
autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = highlight_group,
  callback = function()
    vim.hl.on_yank({ timeout = 170 })
  end,
})

local package_group = augroup('Packages', { clear = true })

-- Remove orphan plugins that are installed but no longer declared via vim.pack.add().
autocmd('VimEnter', {
  desc = 'Prune vim.pack plugins not declared this session',
  group = package_group,
  callback = function()
    local orphans = {}
    for _, p in ipairs(vim.pack.get()) do
      if not p.active then
        table.insert(orphans, p.spec.name)
      end
    end
    if #orphans > 0 then
      vim.notify('Removing ' .. #orphans .. ' orphan packages')
      vim.pack.del(orphans)
    end
  end,
})
