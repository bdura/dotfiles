# # Claude Code
#
# Anthropic's Claude Code CLI, wrapped so that its state lives
# under `$XDG_CONFIG_HOME/claude` rather than `$HOME/.claude`.
# The wrapper also renames the binary from `claude-code` to
# `claude`, matching upstream's preferred invocation.
#
# - Adds the wrapped binary to `environment.systemPackages`,
#   alongside `rtk` (the sandbox-aware command wrapper that all
#   CLIs are routed through on this system).
# - Registers `claude-code` with `my.allowedUnfree` (the upstream
#   package is proprietary).
{
  lib,
  pkgs,
  wrappers,
  config,
  ...
}:
with lib; let
  cfg = config.my.programs.claude;
  claude = wrappers.lib.wrapPackage {
    pkgs = pkgs;
    package = pkgs.claude-code;
    binName = "claude";
    env = {
      CLAUDE_CONFIG_DIR = "$HOME/.config/claude";
    };
  };
in {
  options.my.programs.claude = {
    enable = mkEnableOption "Claude Code CLI";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      claude
      pkgs.rtk
    ];
    my.allowedUnfree = [pkgs.claude-code];
  };
}
