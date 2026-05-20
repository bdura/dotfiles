# # Bitwarden Desktop
#
# Bitwarden's desktop password manager.
#
# This module:
#
# - Adds `bitwarden-desktop` to `environment.systemPackages`.
# - Sets `SSH_AUTH_SOCK` to the path of Bitwarden's SSH-agent
#   socket (`$HOME/.bitwarden-ssh-agent.sock`).
#   See <https://bitwarden.com/help/ssh-agent/> for mor information.
# - Flips `my.needsOzoneWayland = true` because the app is Electron
#   and otherwise falls back to XWayland (degraded HiDPI, broken
#   global shortcuts, fractional-scaling artefacts).
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
