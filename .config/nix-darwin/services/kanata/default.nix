{
  pkgs,
  ...
}:
let
  colorReset = "\\033[0m";
  colorBold = "\\033[1m";
  colorGreen = "\\033[0;32m";
  colorYellow = "\\033[1;33m";

  stateDir = "/tmp/lib/nix-darwin-state";
  packageHashFile = "${stateDir}/kanata-hash.txt";
in
{
  config = {
    environment.systemPackages = [ pkgs.kanata ];

    system.activationScripts.postUserActivation.text = ''
      # State directory and file for tracking changes
      STATE_DIR="${stateDir}"
      PACKAGE_FILE="${packageHashFile}"

      # Ensure state directory exists
      mkdir -p "''$STATE_DIR"

      show_reminder() {
        echo ""
        echo -e "${colorGreen}${colorBold}✅ nix-darwin rebuild completed!${colorReset}"
        echo -e "${colorYellow}Remember to check Input Monitoring permissions for the following package(s)${colorReset}"
        echo -e "${colorYellow}• ${pkgs.kanata}${colorReset}"
        echo ""
      }

      flag=true

      if [ -f "''$PACKAGE_FILE" ]; then
        previous_packages_str=''$(cat "''$PACKAGE_FILE")
        if [ "''$previous_packages_str" = "${pkgs.kanata}" ]; then
          flag=false
        fi
      fi

      if [ "''$flag" = "true" ]; then
        show_reminder
      fi

      echo ${pkgs.kanata} > ''$PACKAGE_FILE
    '';

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
