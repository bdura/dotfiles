---@diagnostic disable: deprecated

--- Asks rust-analyzer to re-read `Cargo.toml` and refresh the workspace
--- without restarting the server. Useful after editing dependencies.
---
---@param bufnr integer Buffer whose attached rust-analyzer clients should reload.
local function reload_workspace(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = 'rust-analyzer' })
  for _, client in ipairs(clients) do
    vim.notify('Reloading Cargo Workspace')
    ---@diagnostic disable-next-line:param-type-mismatch
    client:request('rust-analyzer/reloadWorkspace', nil, function(err)
      if err then
        error(tostring(err))
      end
      vim.notify('Cargo workspace reloaded')
    end, 0)
  end
end

--- Reads an explicit sysroot source path from the user's rust-analyzer
--- config, if one was set. Lets the user override the auto-detected path
--- (e.g. when using a custom toolchain).
---
---@return string? path Configured sysroot source directory, or nil if unset.
local function user_sysroot_src()
  return vim.tbl_get(vim.lsp.config['rust-analyzer'], 'settings', 'rust-analyzer', 'cargo', 'sysrootSrc')
end

--- Computes the default location of the Rust standard library sources by
--- shelling out to `rustc --print sysroot`. We need this path to recognise
--- when a buffer points into stdlib code so we can reuse an existing
--- rust-analyzer instance instead of spawning a new one rooted in the
--- toolchain directory.
---
---@return string? path Absolute path to `<sysroot>/lib/rustlib/src/rust/library`, or nil if rustc failed.
local function default_sysroot_src()
  local sysroot = vim.tbl_get(vim.lsp.config['rust-analyzer'], 'settings', 'rust-analyzer', 'cargo', 'sysroot')
  if not sysroot then
    local rustc = os.getenv('RUSTC') or 'rustc'
    local result = vim.system({ rustc, '--print', 'sysroot' }, { text = true }):wait()

    local stdout = result.stdout
    if result.code == 0 and stdout then
      if string.sub(stdout, #stdout) == '\n' then
        if #stdout > 1 then
          sysroot = string.sub(stdout, 1, #stdout - 1)
        else
          sysroot = ''
        end
      else
        sysroot = stdout
      end
    end
  end

  return sysroot and vim.fs.joinpath(sysroot, 'lib/rustlib/src/rust/library') or nil
end

--- Detects whether a file lives inside a Rust library or toolchain
--- directory (rustup toolchain, cargo registry, git checkouts, or stdlib
--- sources). When the user jumps into one of those locations from a
--- project file we want to reuse the project's existing rust-analyzer
--- instance instead of spawning a new one rooted at the dependency tree.
---
---@param fname string Absolute path of the buffer being opened.
---@return string? root_dir Existing client `root_dir` to reuse, or nil if `fname` is not a library path.
local function is_library(fname)
  local user_home = vim.fs.normalize(vim.env.HOME)
  local cargo_home = os.getenv('CARGO_HOME') or user_home .. '/.cargo'
  local registry = cargo_home .. '/registry/src'
  local git_registry = cargo_home .. '/git/checkouts'

  local rustup_home = os.getenv('RUSTUP_HOME') or user_home .. '/.rustup'
  local toolchains = rustup_home .. '/toolchains'

  local sysroot_src = user_sysroot_src() or default_sysroot_src()

  for _, item in ipairs({ toolchains, registry, git_registry, sysroot_src }) do
    if item and vim.fs.relpath(item, fname) then
      local clients = vim.lsp.get_clients({ name = 'rust-analyzer' })
      return #clients > 0 and clients[#clients].config.root_dir or nil
    end
  end
end

--- Resolves the root directory rust-analyzer should attach to.
---
--- Three cases, in order:
---   1. Buffer is inside a library/toolchain path → reuse an existing
---      client's root so we don't spawn a new server in the registry.
---   2. Buffer is part of a Cargo project → ask `cargo metadata` for the
---      true `workspace_root`, since a `Cargo.toml` may be a workspace
---      member and we want one server per workspace, not per crate.
---   3. No Cargo project → fall back to `rust-project.json` (used by
---      non-Cargo build systems) or the enclosing git repo.
---
---@param bufnr integer Buffer the client is attaching to.
---@param on_dir fun(dir: string?) Callback invoked with the resolved root (or nil to skip attaching).
local function root_dir(bufnr, on_dir)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local reused_dir = is_library(fname)
  if reused_dir then
    on_dir(reused_dir)
    return
  end

  local cargo_crate_dir = vim.fs.root(fname, { 'Cargo.toml' })
  local cargo_workspace_root

  if cargo_crate_dir == nil then
    on_dir(
      vim.fs.root(fname, { 'rust-project.json' })
        or vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
    )
    return
  end

  local cmd = {
    'cargo',
    'metadata',
    '--no-deps',
    '--format-version',
    '1',
    '--manifest-path',
    cargo_crate_dir .. '/Cargo.toml',
  }

  vim.system(cmd, { text = true }, function(output)
    if output.code == 0 then
      if output.stdout then
        local result = vim.json.decode(output.stdout)
        if result['workspace_root'] then
          cargo_workspace_root = vim.fs.normalize(result['workspace_root'])
        end
      end

      on_dir(cargo_workspace_root or cargo_crate_dir)
    else
      vim.schedule(function()
        vim.notify(('[rust-analyzer] cmd failed with code %d: %s\n%s'):format(output.code, cmd, output.stderr))
      end)
    end
  end)
end

--- Runs once before the LSP `initialize` request is sent.
---
--- Two responsibilities:
---
---   1. rust-analyzer reads its config from `initializationOptions` at
---      startup rather than from `workspace/didChangeConfiguration`, so
---      we copy the settings tree across.
---      See https://github.com/rust-lang/rust-analyzer/blob/eb5da56d839ae0a9e9f50774fa3eb78eb0964550/docs/dev/lsp-extensions.md?plain=1#L26
---   2. Register the client-side handler for the `runSingle` code lens
---      command. rust-analyzer only emits the lens; actually invoking
---      cargo is the editor's job.
---
---@param init_params lsp.InitializeParams Mutable params sent to the server.
---@param config vim.lsp.Config Resolved config for this client.
local function before_init(init_params, config)
  if config.settings and config.settings['rust-analyzer'] then
    init_params.initializationOptions = config.settings['rust-analyzer']
  end

  --- Handles the `rust-analyzer.runSingle` code-lens command by
  --- assembling and running the corresponding `cargo` invocation.
  ---@param command { title: string, command: string, arguments: { args: { cargoArgs: string[], executableArgs: string[]?, cwd: string, environment: table<string, string>? } }[] }
  vim.lsp.commands['rust-analyzer.runSingle'] = function(command)
    local r = command.arguments[1]
    local cmd = { 'cargo', unpack(r.args.cargoArgs) }
    if r.args.executableArgs and #r.args.executableArgs > 0 then
      vim.list_extend(cmd, { '--', unpack(r.args.executableArgs) })
    end

    local proc = vim.system(cmd, { cwd = r.args.cwd, env = r.args.environment })

    local result = proc:wait()

    if result.code == 0 then
      vim.notify(result.stdout, vim.log.levels.INFO)
    else
      vim.notify(result.stderr, vim.log.levels.ERROR)
    end
  end
end

--- Runs after the client successfully attaches to a buffer.
--- Registers `:LspCargoReload` so the user can manually trigger a
--- workspace refresh after editing `Cargo.toml`.
---
---@param _ vim.lsp.Client The attached client (unused).
---@param bufnr integer Buffer the client just attached to.
local function on_attach(_, bufnr)
  vim.api.nvim_buf_create_user_command(bufnr, 'LspCargoReload', function()
    reload_workspace(bufnr)
  end, { desc = 'Reload current cargo workspace' })
end

---@type vim.lsp.Config
return {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_dir = root_dir,
  capabilities = {
    experimental = {
      serverStatusNotification = true,
      commands = {
        commands = {
          'rust-analyzer.showReferences',
          'rust-analyzer.runSingle',
          'rust-analyzer.debugSingle',
        },
      },
    },
  },
  settings = {
    ['rust-analyzer'] = {
      checkOnSave = {
        command = 'clippy',
        allTargets = true,
        allFeatures = true,
      },
      lens = {
        debug = { enable = true },
        enable = true,
        implementations = { enable = true },
        references = {
          adt = { enable = true },
          enumVariant = { enable = true },
          method = { enable = true },
          trait = { enable = true },
        },
        run = { enable = true },
        updateTest = { enable = true },
      },
    },
  },
  before_init = before_init,
  on_attach = on_attach,
}
