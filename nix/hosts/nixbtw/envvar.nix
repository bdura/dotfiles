# # XDG Base Directory policy
#
# These environment variables are set unconditionally, regardless of
# whether the corresponding tool is currently installed. The goal is
# forward-leaning: if a tool ever lands on this system (via nix,
# direnv, uv, pipx, an ad-hoc install, …) it should already respect
# the XDG Base Directory Specification without us having to remember
# to redirect it after the fact.
#
# Catalogue inspired by <https://github.com/b3nj5m1n/xdg-ninja>.
{...}: let
  xdgConfigHome = "$HOME/.config";
  xdgDataHome = "$HOME/.local/share";
  xdgCacheHome = "$HOME/.cache";
  xdgStateHome = "$HOME/.local/state";

  inConfig = p: "${xdgConfigHome}/${p}";
  inData = p: "${xdgDataHome}/${p}";
  inCache = p: "${xdgCacheHome}/${p}";
  inState = p: "${xdgStateHome}/${p}";
in {
  environment.variables = {
    # XDG Base Directories
    XDG_CONFIG_HOME = xdgConfigHome;
    XDG_DATA_HOME = xdgDataHome;
    XDG_CACHE_HOME = xdgCacheHome;
    XDG_STATE_HOME = xdgStateHome;

    # Rust
    CARGO_HOME = inData "cargo";
    RUSTUP_HOME = inData "rustup";

    # Docker
    DOCKER_CONFIG = inConfig "docker";

    # GnuPG
    GNUPGHOME = inData "gnupg";

    # Node/NPM
    NPM_CONFIG_USERCONFIG = inConfig "npm/npmrc";
    NPM_CONFIG_CACHE = inCache "npm";
    NODE_REPL_HISTORY = inData "node_repl_history";

    # Python
    IPYTHONDIR = inConfig "ipython";
    JUPYTER_CONFIG_DIR = inConfig "jupyter";
    PYTHONSTARTUP = inConfig "python/pythonrc";
    PYTHON_HISTORY = inState "python_history";
    MPLCONFIGDIR = inConfig "matplotlib";

    # Haskell
    GHCUP_USE_XDG_DIRS = "1";
    CABAL_DIR = inData "cabal";
    CABAL_CONFIG = inConfig "cabal/config";

    # AWS
    AWS_CONFIG_FILE = inConfig "aws/config";
    AWS_DATA_PATH = inData "aws";

    # Bun
    BUN_INSTALL_CACHE_DIR = inData "bun";

    # Go
    GOPATH = inData "go";

    # Kubernetes
    KUBECONFIG = inConfig "kube/config";

    # less
    LESSHISTFILE = inCache "less/history";

    # readline
    INPUTRC = inConfig "readline/inputrc";

    # wget
    WGETRC = inConfig "wget/wgetrc";

    # SQLite
    SQLITE_HISTORY = inData "sqlite/history";

    # PostgreSQL client
    PSQL_HISTORY = inData "psql/history";
    PSQLRC = inConfig "psql/psqlrc";

    # Azure CLI
    AZURE_CONFIG_DIR = inData "azure";

    # .NET
    DOTNET_CLI_HOME = inData "dotnet";

    # GTK 2
    GTK2_RC_FILES = inConfig "gtk-2.0/gtkrc";

    # Bash (history). Fish is the login shell, but bash scripts/REPLs
    # occasionally run and would otherwise write to ~/.bash_history.
    HISTFILE = inState "bash/history";
  };
}
