# skhd is a hotkey deamon for macOS.
#
# Refer to the github page: <https://github.com/koekeishiya/skhd>.
#
# skhd supports hot reloading, so the configuration is in `.config` directly.
#
# I have been unable to make it work as a launchd service, whether through nix or not.
# Calling it directly works fine, though.
#
# The issue may stem from an inability to listen for hotkeys when launched as a service?

{
  pkgs,
  ...
}:
{
  launchd.user.agents.skhd = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.skhd}/bin/skhd"
        "-V"
      ];
      KeepAlive = true;
      StandardOutPath = /tmp/skhd.out;
      StandardErrorPath = /tmp/skhd.err;
    };
  };
}
