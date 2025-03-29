{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = [ pkgs.kanata ];

    # NOTE: this is quite ugly... Since this part is *not* handled by Nix.
    launchd.daemons.karabiner_driver = {
      serviceConfig = {
        ProgramArguments = [
          "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
        ];
        RunAtLoad = true;
        KeepAlive = true;
      };
    };

    # TODO: make this a user agent.
    launchd.daemons.kanata = {
      # NOTE: we *need* to use a `command` here, because it wraps the call to kanata
      # with a `wait4path`, which makes sure that the nix store is mounted.
      # Without `command`, launchd exits with error code 78 ("function not implemented"),
      # and does not try to relaunch it even if keepalive is set - since from its point of view
      # the program does not even exist.
      command = "${pkgs.kanata}/bin/kanata -c ${./config.kbd}";
      serviceConfig = {
        # NOTE: this allows ctrl + space + esc to be used as an escape hatch.
        KeepAlive = {
          SuccessfulExit = false;
        };
        StandardOutPath = /tmp/kanata.out;
        StandardErrorPath = /tmp/kanata.err;
      };
    };
  };
}
