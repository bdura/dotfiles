-- lsp_inspector.lua — requires Neovim 0.12+
-- Zero dependencies: uses only vim.lsp native APIs.
--
-- Install: place at ~/.config/nvim/lua/lsp_inspector.lua
--
-- Wire up in init.lua:
--   require("lsp_inspector").setup()           -- registers :LspInspector
--   require("lsp_inspector").setup({ command = "LI" })  -- custom name
--
-- Or call directly:
--   require("lsp_inspector").open()

local M = {}

-- ─── tiny helpers ─────────────────────────────────────────────────────────────

local function pad(s, width)
  s = tostring(s or '')
  return s .. string.rep(' ', math.max(0, width - #s))
end

local function bool_icon(v)
  return v and '✓' or '✗'
end

-- ─── capability table ─────────────────────────────────────────────────────────
-- Uses client:supports_method() — idiomatic 0.11+/0.12 API.

-- stylua: ignore start
local CAPABILITIES = {
  -- Navigation
  { label = "hover",            method = "textDocument/hover" },
  { label = "definition",       method = "textDocument/definition" },
  { label = "declaration",      method = "textDocument/declaration" },
  { label = "typeDefinition",   method = "textDocument/typeDefinition" },
  { label = "implementation",   method = "textDocument/implementation" },
  { label = "references",       method = "textDocument/references" },
  -- Editing
  { label = "completion",       method = "textDocument/completion" },
  { label = "signatureHelp",    method = "textDocument/signatureHelp" },
  { label = "rename",           method = "textDocument/rename" },
  { label = "codeAction",       method = "textDocument/codeAction" },
  { label = "formatting",       method = "textDocument/formatting" },
  { label = "rangeFormatting",  method = "textDocument/rangeFormatting" },
  { label = "onTypeFormatting", method = "textDocument/onTypeFormatting" },
  -- Symbols
  { label = "documentSymbol",   method = "textDocument/documentSymbol" },
  { label = "workspaceSymbol",  method = "workspace/symbol" },
  { label = "codeLens",         method = "textDocument/codeLens" },
  -- Highlights & decorations
  { label = "docHighlight",     method = "textDocument/documentHighlight" },
  { label = "semanticTokens",   method = "textDocument/semanticTokens/full" },
  { label = "inlayHints",       method = "textDocument/inlayHint" },
  { label = "inlineValue",      method = "textDocument/inlineValue" },
  -- Misc
  { label = "foldingRange",     method = "textDocument/foldingRange" },
  { label = "selectionRange",   method = "textDocument/selectionRange" },
  { label = "callHierarchy",    method = "textDocument/prepareCallHierarchy" },
  { label = "typeHierarchy",    method = "textDocument/prepareTypeHierarchy" },
  { label = "diagnostics",      method = "textDocument/diagnostic" },
}
-- stylua: ignore end

-- ─── data gathering ───────────────────────────────────────────────────────────

-- Returns a sorted list of server info tables for every server registered via
-- vim.lsp.config / lsp/*.lua files (the 0.11+ native config mechanism).
local function get_configured_servers(attached_by_name)
  local servers = {}

  -- vim.lsp.config behaves like a table: pairs() iterates configured names.
  -- The special "*" wildcard entry is not a real server — skip it.
  for name, _ in pairs(vim.lsp.config) do
    if type(name) == 'string' and name ~= '*' then
      -- Accessing vim.lsp.config[name] resolves and returns the config.
      local cfg = vim.lsp.config[name] or {}
      table.insert(servers, {
        name = name,
        enabled = vim.lsp.is_enabled(name),
        client = attached_by_name[name],
        filetypes = cfg.filetypes or {},
        root_markers = cfg.root_markers or {},
        cmd = type(cfg.cmd) == 'table' and cfg.cmd or {},
      })
    end
  end

  table.sort(servers, function(a, b)
    return a.name < b.name
  end)
  return servers
end

-- ─── line buffer with highlight tracking ─────────────────────────────────────

local function new_buf()
  return { lines = {}, hl = {} }
end

-- Append one line; hls = list of { col_start, col_end, hl_group } (0-indexed)
local function push(b, text, hls)
  local idx = #b.lines -- 0-based line index after insert
  b.lines[idx + 1] = text
  if hls then
    for _, h in ipairs(hls) do
      b.hl[#b.hl + 1] = { idx, h[1], h[2], h[3] }
    end
  end
end

local function section_header(b, title)
  push(b, '')
  push(b, '  ' .. title, { { 2, 2 + #title, 'Title' } })
  push(b, '  ' .. string.rep('─', 64), { { 2, 66, 'Comment' } })
end

-- ─── rendering ────────────────────────────────────────────────────────────────

local function render(src_bufnr)
  local b = new_buf()

  local attached = vim.lsp.get_clients({ bufnr = src_bufnr })

  local attached_by_name = {}
  for _, c in ipairs(attached) do
    attached_by_name[c.name] = c
  end

  -- ── Header ────────────────────────────────────────────────────────────────
  local fname = vim.api.nvim_buf_get_name(src_bufnr)
  fname = fname ~= '' and vim.fn.fnamemodify(fname, ':~:.') or '[No Name]'
  local ft = vim.bo[src_bufnr].filetype
  push(b, '  LSP Inspector', { { 2, 15, 'Title' } })
  push(b, ('  buf %-4d  %s  [%s]'):format(src_bufnr, fname, ft), { { 2, 5, 'Comment' } })

  -- ── Attached clients ──────────────────────────────────────────────────────
  section_header(b, ('Attached clients (%d)'):format(#attached))

  if #attached == 0 then
    push(b, '    (none)', { { 4, 10, 'Comment' } })
  else
    for _, c in ipairs(attached) do
      local id_str = ('[%d]'):format(c.id)
      local line = ('    %s %s'):format(id_str, c.name)
      push(b, line, {
        { 4, 4 + #id_str, 'Number' },
        { 5 + #id_str, #line, 'Function' },
      })
      local root = (c.root_dir and c.root_dir ~= '') and vim.fn.fnamemodify(c.root_dir, ':~') or '(no root)'
      local cmd_str = type(c.config.cmd) == 'table' and table.concat(c.config.cmd, ' ') or tostring(c.config.cmd or '?')
      push(b, ('      root  %s'):format(root), { { 6, 12, 'Comment' } })
      push(b, ('      cmd   %s'):format(cmd_str), { { 6, 12, 'Comment' } })
      push(b, '')
    end
  end

  -- ── Configured servers ────────────────────────────────────────────────────
  local servers = get_configured_servers(attached_by_name)
  section_header(b, ('Configured servers (%d)'):format(#servers))

  if #servers == 0 then
    push(b, '    (none — configure servers with vim.lsp.config / lsp/*.lua)', { { 4, 70, 'Comment' } })
  else
    local NAME_W = 24
    -- table header
    local hdr = ('    %s  %s  %s  %s'):format(
      pad('server', NAME_W),
      pad('enabled', 9),
      pad('attached', 10),
      'filetypes'
    )
    push(b, hdr, { { 4, #hdr, 'Comment' } })
    push(b, '    ' .. string.rep('·', #hdr - 4), { { 4, #hdr, 'Comment' } })

    for _, s in ipairs(servers) do
      local en_icon = s.enabled and '✓ yes' or '✗ no '
      local en_hl = s.enabled and 'DiagnosticOk' or 'DiagnosticWarn'
      local at_icon = s.client and '● attached' or '○ none    '
      local at_hl = s.client and 'DiagnosticOk' or 'DiagnosticHint'
      local fts = #s.filetypes > 0 and table.concat(s.filetypes, ', ') or '—'

      local c0 = 4
      local c1 = c0 + NAME_W + 2
      local c2 = c1 + 9 + 2
      local c3 = c2 + 10 + 2
      local line = ('    %s  %s  %s  %s'):format(pad(s.name, NAME_W), pad(en_icon, 9), pad(at_icon, 10), fts)

      push(b, line, {
        { c0, c0 + #s.name, 'Identifier' },
        { c1, c1 + #en_icon, en_hl },
        { c2, c2 + #at_icon, at_hl },
        { c3, #line, 'Type' },
      })
    end
    push(b, '')
  end

  -- ── Capability matrix ─────────────────────────────────────────────────────
  if #attached > 0 then
    section_header(b, 'Capability matrix')
    push(b, '')

    local LABEL_W = 18
    local COL_W = math.max(10, math.floor((72 - LABEL_W) / #attached))

    -- column header row
    local hdr = '    ' .. pad('', LABEL_W)
    local col_pos = {}
    for _, c in ipairs(attached) do
      col_pos[#col_pos + 1] = #hdr
      hdr = hdr .. pad(c.name, COL_W)
    end
    local hdr_hls = {}
    for i, c in ipairs(attached) do
      hdr_hls[#hdr_hls + 1] = { col_pos[i], col_pos[i] + #c.name, 'Function' }
    end
    push(b, hdr, hdr_hls)
    push(b, '    ' .. string.rep('·', #hdr - 4), { { 4, #hdr, 'Comment' } })

    for _, cap in ipairs(CAPABILITIES) do
      local row = '    ' .. pad(cap.label, LABEL_W)
      local row_hls = {}
      local any = false

      for i, c in ipairs(attached) do
        local ok = c:supports_method(cap.method)
        if ok then
          any = true
        end
        local icon = bool_icon(ok)
        local offset = math.floor((COL_W - 1) / 2)
        local col = col_pos[i] + offset
        row = row .. pad(string.rep(' ', offset) .. icon, COL_W)
        row_hls[#row_hls + 1] = { col, col + 1, ok and 'DiagnosticOk' or 'DiagnosticWarn' }
      end

      push(b, row, vim.list_extend({ { 4, 4 + #cap.label, any and 'Normal' or 'Comment' } }, row_hls))
    end
    push(b, '')
  end

  -- ── Footer ────────────────────────────────────────────────────────────────
  push(b, '  q/<Esc> close · r refresh', { { 2, 28, 'Comment' } })

  return b
end

-- ─── window / buffer plumbing ─────────────────────────────────────────────────

local NS = vim.api.nvim_create_namespace('lsp_inspector')
local state = { buf = nil, win = nil, src = nil }

local function apply(buf, rendered)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, rendered.lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
  for _, h in ipairs(rendered.hl) do
    -- h = { line, col_start, col_end, group }
    pcall(vim.api.nvim_buf_add_highlight, buf, NS, h[4], h[1], h[2], h[3])
  end
end

local function refresh()
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    return
  end
  apply(state.buf, render(state.src))
end

function M.open()
  local src = vim.api.nvim_get_current_buf()

  -- Reuse existing window if already open
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    state.src = src
    vim.api.nvim_set_current_win(state.win)
    refresh()
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'lsp-inspector'

  vim.cmd('botright split')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_height(win, math.min(45, math.floor(vim.o.lines * 0.55)))

  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].spell = false
  vim.wo[win].cursorline = true

  state = { buf = buf, win = win, src = src }
  apply(buf, render(src))

  local function map(lhs, fn)
    vim.keymap.set('n', lhs, fn, { buffer = buf, nowait = true, silent = true })
  end
  map('q', function()
    vim.api.nvim_win_close(win, true)
  end)
  map('<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end)
  map('r', refresh)
end

-- ─── setup ────────────────────────────────────────────────────────────────────

function M.setup(opts)
  opts = opts or {}
  vim.api.nvim_create_user_command(
    opts.command or 'LspInspector',
    M.open,
    { desc = 'Open human-friendly LSP inspector' }
  )
end

return M
