---@type vim.lsp.Config
return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      hint = { enable = true },
      completion = { enable = true, callSnippet = 'Replace' },
      workspace = {
        library = { vim.env.VIMRUNTIME .. '/lua' },
        checkThirdParty = false,
      },
    },
  },
}
