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

local function show_lsp_matrix()
  local clients = vim.lsp.get_clients()
  if #clients == 0 then
    vim.notify('No LSP clients attached', vim.log.levels.WARN)
    return
  end

  local capability_w = 0
  for _, section in ipairs(CAPABILITY_SECTIONS) do
    capability_w = math.max(capability_w, #section.name)
    for _, capability in ipairs(section.caps) do
      capability_w = math.max(capability_w, #capability.label)
    end
  end
  capability_w = capability_w + 2

  -- Column widths
  local widths = {}
  for _, c in ipairs(clients) do
    table.insert(widths, #c.name + 1)
  end

  -- Build lines, recording highlight ranges as we go.
  -- Ranges are byte offsets, which equals display width for the ASCII
  -- portions; the only multi-byte glyphs are the ✓/✗ marks.
  local lines = {}
  local highlights = {}

  local header = pad('', capability_w, 'prepend')
  local col = capability_w
  for i, c in ipairs(clients) do
    local w = widths[i]
    header = header .. pad(c.name, w, 'prepend')
    table.insert(highlights, {
      line = #lines,
      col_start = col + (w - #c.name),
      col_end = col + w,
      hl = 'Title',
    })
    col = col + w
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
      local cur = capability_w

      for i, client in ipairs(clients) do
        local ok = client:supports_method(capability.method)
        local mark = ok and '✓' or '✗'
        local w = widths[i]
        line = line .. pad(mark, w, 'prepend')
        -- pad prepends (w - 1) ASCII spaces, then the 3-byte mark.
        local mark_start = cur + (w - 1)
        table.insert(highlights, {
          line = line_idx,
          col_start = mark_start,
          col_end = mark_start + #mark,
          hl = ok and 'DiagnosticOk' or 'DiagnosticError',
        })
        cur = mark_start + #mark
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

  -- Floating window
  local width = #lines[1] + 2
  local height = #lines
  local ui = vim.api.nvim_list_uis()[1]
  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = math.min(width, ui.width - 4),
    height = math.min(height, ui.height - 4),
    col = math.floor((ui.width - width) / 2),
    row = math.floor((ui.height - height) / 2),
    style = 'minimal',
    border = 'single',
    title = ' LSP capability matrix ',
    title_pos = 'center',
  })

  -- Close with q or <Esc>
  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf, nowait = true })
  vim.keymap.set('n', '<Esc>', '<cmd>close<cr>', { buffer = buf, nowait = true })
end

vim.api.nvim_create_user_command('LspMatrix', show_lsp_matrix, {})
