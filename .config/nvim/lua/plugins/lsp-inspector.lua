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

-- The 'single' border adds one cell on each side, so the visible
-- frame is `width + WINDOW_BORDER` by `height + WINDOW_BORDER`.
-- Centring math has to account for it.
local WINDOW_BORDER = 2

-- Empty cells reserved on each side of the matrix, inside the border,
-- so the content sits centred rather than flush against the frame.
local INNER_PADDING = 1

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

-- Open-window state. Tracked so refresh() can find the buffer/window
-- and so a re-invocation of :LspMatrix replaces the existing window
-- rather than stacking duplicates.
local state = {}

--- Build the matrix lines and highlight ranges for the given origin
--- buffer. Returns nil if no clients qualify.
---@param origin_buf integer Buffer used for the supports_method check
---  (so dynamically-registered methods resolve against the right doc).
---@param buffer_only boolean Restrict client list to that buffer's clients.
---@return { lines: string[], highlights: table[] }?
local function build_content(origin_buf, buffer_only)
  local clients = buffer_only and vim.lsp.get_clients({ bufnr = origin_buf }) or vim.lsp.get_clients()
  if #clients == 0 then
    return nil
  end

  table.sort(clients, function(a, b)
    return a.name < b.name
  end)

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

  -- Shift every line right by INNER_PADDING so the content is centred
  -- inside the float (the window width adds the same amount on the
  -- right). Highlight byte offsets shift along with the prefix.
  if INNER_PADDING > 0 then
    local prefix = string.rep(' ', INNER_PADDING)
    for i, line in ipairs(lines) do
      lines[i] = prefix .. line
    end
    for _, h in ipairs(highlights) do
      h.col_start = h.col_start + INNER_PADDING
      h.col_end = h.col_end + INNER_PADDING
    end
  end

  return { lines = lines, highlights = highlights }
end

--- Compute the centred floating-window dimensions for the given lines.
--- `width`/`height` size the inner content area; the visible frame
--- is larger by `WINDOW_BORDER` on each axis, which the centring math
--- must subtract before halving.
local function window_dims(lines)
  local ui = vim.api.nvim_list_uis()[1]
  -- lines[1] already carries INNER_PADDING on the left; the trailing
  -- INNER_PADDING is added here so the gutter is symmetric.
  local width = math.min(vim.fn.strdisplaywidth(lines[1]) + INNER_PADDING, ui.width - 4)
  local height = math.min(#lines, ui.height - 4)
  return {
    width = width,
    height = height,
    col = math.max(0, math.floor((ui.width - width - WINDOW_BORDER) / 2)),
    row = math.max(0, math.floor((ui.height - height - WINDOW_BORDER) / 2)),
  }
end

--- Apply content to the buffer and resize the window. Used by both the
--- initial draw and refresh().
local function paint(buf, win, ns, content)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content.lines)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, h in ipairs(content.highlights) do
    vim.api.nvim_buf_set_extmark(buf, ns, h.line, h.col_start, {
      end_col = h.col_end,
      hl_group = h.hl,
    })
  end
  vim.bo[buf].modifiable = false

  local dims = window_dims(content.lines)
  vim.api.nvim_win_set_config(win, vim.tbl_extend('force', { relative = 'editor' }, dims))
end

--- Refresh the matrix in the open window (if any).
local function refresh()
  if not (state.win and vim.api.nvim_win_is_valid(state.win)) then
    return
  end
  local content = build_content(state.origin_buf, state.buffer_only)
  if not content then
    local msg = state.buffer_only and 'No LSP clients attached to this buffer' or 'No LSP clients attached'
    vim.notify(msg, vim.log.levels.WARN)
    return
  end
  paint(state.buf, state.win, state.ns, content)
end

--- Show the LSP capability matrix.
---@param opts? { buffer_only?: boolean } If buffer_only, restrict to clients
--- attached to the current buffer and check capabilities against that buffer
--- (so dynamically-registered methods are reflected).
local function show_lsp_matrix(opts)
  opts = opts or {}

  -- Replace any existing window so origin_buf and buffer_only reflect
  -- the new invocation. The WinClosed autocmd resets `state`.
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end

  local origin_buf = vim.api.nvim_get_current_buf()
  local content = build_content(origin_buf, opts.buffer_only)
  if not content then
    local msg = opts.buffer_only and 'No LSP clients attached to this buffer' or 'No LSP clients attached'
    vim.notify(msg, vim.log.levels.WARN)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'

  local dims = window_dims(content.lines)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = dims.width,
    height = dims.height,
    col = dims.col,
    row = dims.row,
    style = 'minimal',
    border = 'single',
    title = opts.buffer_only and ' LSP capability matrix (buffer) ' or ' LSP capability matrix ',
    title_pos = 'center',
  })

  state = {
    win = win,
    buf = buf,
    ns = vim.api.nvim_create_namespace('lsp_matrix'),
    origin_buf = origin_buf,
    buffer_only = opts.buffer_only or false,
  }

  paint(state.buf, state.win, state.ns, content)

  -- Close with q or <Esc>; refresh with R.
  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = buf, nowait = true })
  vim.keymap.set('n', '<Esc>', '<cmd>close<cr>', { buffer = buf, nowait = true })
  vim.keymap.set('n', 'R', refresh, { buffer = buf, nowait = true, desc = 'Refresh LSP matrix' })

  -- Swallow jumplist motions so the inspector window can't navigate
  -- away from itself.
  for _, lhs in ipairs({ '<C-o>', '<C-i>', '<Tab>' }) do
    vim.keymap.set('n', lhs, '<Nop>', { buffer = buf, nowait = true })
  end

  vim.api.nvim_create_autocmd('WinClosed', {
    pattern = tostring(win),
    once = true,
    callback = function()
      state = {}
    end,
  })
end

---@param opts table? Options passed to the setup function
local function setup(opts)
  vim.api.nvim_create_user_command('LspInspector', function(args)
    show_lsp_matrix({ buffer_only = args.bang })
  end, { bang = true, desc = 'Show LSP capability matrix (! to scope to current buffer)' })
end

local M = {}

M.show_lsp_matrix = show_lsp_matrix
M.refresh = refresh
M.setup = setup

return M
