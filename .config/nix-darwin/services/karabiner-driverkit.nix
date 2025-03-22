# Taken from <https://github.com/LnL7/nix-darwin/blob/e9f41de2a81f04390afd106959adf352a207628f/modules/services/karabiner-elements/default.nix>.
#
# The original service installs the full Karabiner package, including Karabiner-Elements, but I only use the DriverKit.
{
  config,
  lib,
  ...
}:
with lib;

let
  cfg = config.services.karabiner-driverkit;

  # Sadly, Karabiner *needs* to be included in the /Applications folder
  parentAppDir = "/Applications/.Nix-Karabiner";
in

{
  options.services.karabiner-driverkit = {
    enable = mkEnableOption "Karabiner-DriverKit";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ (callPackage ../packages/karabiner-driverkit.nix { }) ];

    system.activationScripts.preActivation.text = ''
      rm -rf ${parentAppDir}
      mkdir -p ${parentAppDir}
      # Kernel extensions must reside inside of /Applications, they cannot be symlinks
      cp -r ${cfg.package}/driver/Applications/.Karabiner-VirtualHIDDevice-Manager.app ${parentAppDir}
    '';

    # system.activationScripts.postActivation.text = ''
    #   echo "attempt to activate karabiner system extension and start daemons" >&2
    #   launchctl unload /Library/LaunchDaemons/org.nixos.start_karabiner_daemons.plist
    #   launchctl load -w /Library/LaunchDaemons/org.nixos.start_karabiner_daemons.plist
    # '';

    # We need the karabiner_grabber and karabiner_observer daemons to run after the
    # Nix Store has been mounted, but we can't use wait4path as they need to be
    # executed directly for the Input Monitoring permission. We also want these
    # daemons to auto restart but if they start up without the Nix Store they will
    # refuse to run again until they've been unloaded and loaded back in so we can
    # use a helper daemon to start them. We also only want to run the daemons after
    # the system extension is activated, so we can call activate from the manager
    # which will block until the system extension is activated.
    launchd.daemons.start_karabiner_daemons = {
      script = ''
        ${parentAppDir}/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
      '';
      # serviceConfig.Label = "org.nixos.start_karabiner_daemons";
      serviceConfig.RunAtLoad = true;
    };

    launchd.daemons.Karabiner-DriverKit-VirtualHIDDeviceClient = {
      command = "\"${cfg.package}/driver/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-DriverKit-VirtualHIDDeviceClient.app/Contents/MacOS/Karabiner-DriverKit-VirtualHIDDeviceClient\"";
      serviceConfig.ProcessType = "Interactive";
      # serviceConfig.Label = "org.pqrs.Karabiner-DriverKit-VirtualHIDDeviceClient";
      serviceConfig.KeepAlive = true;
    };

    # Normally karabiner_console_user_server calls activate on the manager but
    # because we use a custom location we need to call activate manually.
    launchd.user.agents.activate_karabiner_system_ext = {
      serviceConfig.ProgramArguments = [
        "${parentAppDir}/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"
        "activate"
      ];
      serviceConfig.RunAtLoad = true;
    };
  };
}
