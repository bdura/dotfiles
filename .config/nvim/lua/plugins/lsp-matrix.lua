-- lsp-matrix
--
-- A zero-dependency, simplistic plugin for displaying attached LSP servers
-- and their capabilities.

-- stylua: ignore start
local CAPABILITY_SECTIONS = {
  { name = "Navigation", caps = {
    { label = "hover",            method = "textDocument/hover" },
    { label = "definition",       method = "textDocument/definition" },
    { label = "declaration",      method = "textDocument/declaration" },
    { label = "typeDefinition",   method = "textDocument/typeDefinition" },
    { label = "implementation",   method = "textDocument/implementation" },
    { label = "references",       method = "textDocument/references" },
  }},
  { name = "Editing", caps = {
    { label = "completion",       method = "textDocument/completion" },
    { label = "signatureHelp",    method = "textDocument/signatureHelp" },
    { label = "rename",           method = "textDocument/rename" },
    { label = "codeAction",       method = "textDocument/codeAction" },
    { label = "formatting",       method = "textDocument/formatting" },
    { label = "rangeFormatting",  method = "textDocument/rangeFormatting" },
    { label = "onTypeFormatting", method = "textDocument/onTypeFormatting" },
  }},
  { name = "Symbols", caps = {
    { label = "documentSymbol",   method = "textDocument/documentSymbol" },
    { label = "workspaceSymbol",  method = "workspace/symbol" },
    { label = "codeLens",         method = "textDocument/codeLens" },
  }},
  { name = "Highlights & decorations", caps = {
    { label = "docHighlight",     method = "textDocument/documentHighlight" },
    { label = "semanticTokens",   method = "textDocument/semanticTokens/full" },
    { label = "inlayHints",       method = "textDocument/inlayHint" },
    { label = "inlineValue",      method = "textDocument/inlineValue" },
  }},
  { name = "Misc", caps = {
    { label = "foldingRange",     method = "textDocument/foldingRange" },
    { label = "selectionRange",   method = "textDocument/selectionRange" },
    { label = "callHierarchy",    method = "textDocument/prepareCallHierarchy" },
    { label = "typeHierarchy",    method = "textDocument/prepareTypeHierarchy" },
    { label = "diagnostics",      method = "textDocument/diagnostic" },
  }},
}
-- stylua: ignore end

local CAPABILITY_COLUMN_MARGIN = 3
local SERVER_MARGIN = 3

--- Pad a string to a minimum width with spaces.
---@param s string The string to pad (converted to string if not already).
---@param width integer The minimum width to pad to.
---@param mode "prepend"|"append" Whether to prepend or append padding.
---@return string padded The padded string.
local function pad(s, width, mode)
  local count = width - vim.fn.strdisplaywidth(s)
  assert(count >= 0, 'Padding must be positive')

  local padding = string.rep(' ', count)

  if mode == 'prepend' then
    return padding .. s
  else
    return s .. padding
  end
end

--- Show the LSP capability matrix.
---@param opts? { buffer_only?: boolean } If buffer_only, restrict to clients
--- attached to the current buffer and check capabilities against that buffer
--- (so dynamically-registered methods are reflected).
local function show_lsp_matrix(opts)
  opts = opts or {}
  local origin_buf = vim.api.nvim_get_current_buf()
  local clients = opts.buffer_only and vim.lsp.get_clients({ bufnr = origin_buf }) or vim.lsp.get_clients()
  if #clients == 0 then
    local msg = opts.buffer_only and 'No LSP clients attached to this buffer' or 'No LSP clients attached'
    vim.notify(msg, vim.log.levels.WARN)
    return
  end

  table.sort(clients, function(a, b) return a.name < b.name end)

  local strwidth = vim.fn.strdisplaywidth

  local capability_w = 0
  for _, section in ipairs(CAPABILITY_SECTIONS) do
    capability_w = math.max(capability_w, strwidth(section.name))
    for _, capability in ipairs(section.caps) do
      capability_w = math.max(capability_w, strwidth(capability.label))
    end
  end
  capability_w = capability_w + CAPABILITY_COLUMN_MARGIN

  -- Column widths
  local widths = {}
  for _, c in ipairs(clients) do
    table.insert(widths, strwidth(c.name) + SERVER_MARGIN)
  end

  -- Build lines, recording highlight ranges as we go. Highlight
  -- columns are byte offsets (extmark API), so we track them via the
  -- running line length rather than display width — that way
  -- multi-byte client names stay correct.
  local lines = {}
  local highlights = {}

  local header = pad('', capability_w, 'prepend')
  for i, c in ipairs(clients) do
    local segment = pad(c.name, widths[i], 'prepend')
    local seg_start = #header
    header = header .. segment
    table.insert(highlights, {
      line = #lines,
      col_start = seg_start + #segment - #c.name,
      col_end = seg_start + #segment,
      hl = 'Title',
    })
  end
  table.insert(lines, header)

  for _, section in ipairs(CAPABILITY_SECTIONS) do
    table.insert(lines, '')
    table.insert(highlights, {
      line = #lines,
      col_start = 0,
      col_end = #section.name,
      hl = 'Title',
    })
    table.insert(lines, section.name)

    for _, capability in ipairs(section.caps) do
      local line = pad(capability.label, capability_w, 'append')
      local line_idx = #lines

      for i, client in ipairs(clients) do
        local ok = client:supports_method(capability.method, origin_buf)
        local mark = ok and '✓' or '✗'
        local segment = pad(mark, widths[i], 'prepend')
        local seg_start = #line
        line = line .. segment
        table.insert(highlights, {
          line = line_idx,
          col_start = seg_start + #segment - #mark,
          col_end = seg_start + #segment,
          hl = ok and 'DiagnosticOk' or 'DiagnosticError',
        })
      end
      table.insert(lines, line)
    end
  end

  -- Scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local ns = vim.api.nvim_create_namespace('lsp_matrix')
  for _, h in ipairs(highlights) do
    vim.api.nvim_buf_set_extmark(buf, ns, h.line, h.col_start, {
      end_col = h.col_end,
      hl_group = h.hl,
    })
  end

  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'

  -- Floating window — clamp dimensions to the UI before centring,
  -- otherwise an oversized matrix produces a negative col/row.
  local ui = vim.api.nvim_list_uis()[1]
  local width = math.min(strwidth(lines[1]) + 2, ui.width - 4)
  local height = math.min(#lines, ui.height - 4)

  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((ui.width - width) / 2),
    row = math.floor((ui.height - height) / 2),
    style = 'minimal',
    border = 'single',
    title = opts.buffer_only and ' LSP capability matrix (buffer) ' or ' LSP capability matrix ',
    title_pos = 'center',
  })

  -- Close with q or <Esc>
  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf, nowait = true })
  vim.keymap.set('n', '<Esc>', '<cmd>close<cr>', { buffer = buf, nowait = true })
end

vim.api.nvim_create_user_command('LspMatrix', function(args)
  show_lsp_matrix({ buffer_only = args.bang })
end, { bang = true, desc = 'Show LSP capability matrix (! to scope to current buffer)' })
