# # Bitwarden Desktop
#
# Bitwarden's desktop password manager. The module wires up three
# pieces of state:
#
# - Adds `bitwarden-desktop` to `environment.systemPackages`.
# - Sets `SSH_AUTH_SOCK` to the path of Bitwarden's SSH-agent
#   socket (`$HOME/.bitwarden-ssh-agent.sock`). With this in place,
#   any `ssh` invocation transparently uses keys stored inside
#   Bitwarden once the desktop app is unlocked, so no separate
#   ssh-agent / GnuPG agent is needed.
# - Flips `my.needsOzoneWayland = true` because the app is Electron
#   and otherwise falls back to XWayland (degraded HiDPI, broken
#   global shortcuts, fractional-scaling artefacts).
#
# Not handled here: the Hyprland window rule that floats the
# unlock dialog (`windowrule = float on, match:class ^Bitwarden$`)
# lives in `config/hyprland.nix`. It is home-manager state and
# cannot be expressed cleanly from a system-level NixOS module;
# left in place rather than synthesised across the system /
# home-manager boundary.
{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.my.programs.bitwarden;
in {
  options.my.programs.bitwarden = {
    enable = mkEnableOption "Bitwarden Desktop password manager + SSH agent";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.bitwarden-desktop];

    environment.variables = {
      SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
    };

    my.needsOzoneWayland = true;
  };
}
