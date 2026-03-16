# # Miscellaneous variables
#
# Sets up variables to force as many apps as possible to respect
# the XDG Base Directory Specification.

{
  ...
}:

let
  xdgConfigHome = "$HOME/.config";
  xdgDataHome = "$HOME/.local/share";
  xdgCacheHome = "$HOME/.cache";
  xdgStateHome = "$HOME/.local/state";
in
{
  environment.variables = {
    # XDG Base Directories
    XDG_CONFIG_HOME = xdgConfigHome;
    XDG_DATA_HOME = xdgDataHome;
    XDG_CACHE_HOME = xdgCacheHome;
    XDG_STATE_HOME = xdgStateHome;

    # Rust
    CARGO_HOME = "${xdgDataHome}/cargo";
    RUSTUP_HOME = "${xdgDataHome}/rustup";

    # Docker
    DOCKER_CONFIG = "${xdgConfigHome}/docker";

    # GnuPG
    GNUPGHOME = "${xdgDataHome}/gnupg";

    # Node/NPM
    NPM_CONFIG_USERCONFIG = "${xdgConfigHome}/npm/npmrc";
    NODE_REPL_HISTORY = "${xdgDataHome}/node_repl_history";

    # Python
    IPYTHONDIR = "${xdgConfigHome}/ipython";
    JUPYTER_CONFIG_DIR = "${xdgConfigHome}/jupyter";
    PYTHONSTARTUP = "${xdgConfigHome}/python/pythonrc";
    MPLCONFIGDIR = "${xdgConfigHome}/matplotlib";

    # Haskell
    GHCUP_USE_XDG_DIRS = "1";
    CABAL_DIR = "${xdgDataHome}/cabal";
    CABAL_CONFIG = "${xdgConfigHome}/cabal/config";

    # AWS
    AWS_CONFIG_FILE = "${xdgConfigHome}/aws/config";
    AWS_DATA_PATH = "${xdgDataHome}/aws";

    # Bun
    BUN_INSTALL_CACHE_DIR = "${xdgDataHome}/bun";

    # Claude
    CLAUDE_CONFIG_DIR = "${xdgConfigHome}/claude";
  };
}
