{
  pkgs,
  ...
}:
let
  config = ''
    ;; defsrc is still necessary
    (defcfg
      process-unmapped-keys yes
    )

    (defsrc
      caps a s d f j k l ;
    )

    (defvar
      tap-time 150
      hold-time 200
    )

    (defalias
      escctrl (tap-hold 200 200 esc lctl)
      a (tap-hold $tap-time $hold-time a lmet)
      s (tap-hold $tap-time $hold-time s lalt)
      d (tap-hold $tap-time $hold-time d lsft)
      f (tap-hold $tap-time $hold-time f lctl)
      j (tap-hold $tap-time $hold-time j rctl)
      k (tap-hold $tap-time $hold-time k rsft)
      l (tap-hold $tap-time $hold-time l ralt)
      ; (tap-hold $tap-time $hold-time ; rmet)
    )

    (deflayer base
      @escctrl @a @s @d @f @j @k @l @;
    )
  '';
  configFile = pkgs.writeScript "kanata.kbd" config;
  parentAppDir = "/Applications";
in
{
  config = {
    environment.systemPackages = [ pkgs.kanata ];

    # system.activationScripts.preActivation.text = ''
    #   rm -rf ${parentAppDir}
    #   mkdir -p ${parentAppDir}
    #   # Kernel extensions must reside inside of /Applications, they cannot be symlinks
    #   cp -r ${karabiner.driver}/Applications/.Karabiner-VirtualHIDDevice-Manager.app ${parentAppDir}
    # '';

    system.activationScripts.postActivation.text = ''
      echo "attempt to activate karabiner system extension and start daemons" >&2
      launchctl unload /Library/LaunchDaemons/org.nixos.start_karabiner_daemons.plist
      launchctl load -w /Library/LaunchDaemons/org.nixos.start_karabiner_daemons.plist
    '';

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
        /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
      '';
      serviceConfig.Label = "org.nixos.start_karabiner_daemons";
      serviceConfig.RunAtLoad = true;
    };

    launchd.daemons.Karabiner-DriverKit-VirtualHIDDeviceDaemon = {
      command = "/Library/Application\ Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";

      serviceConfig.ProcessType = "Interactive";
      serviceConfig.Label = "org.pqrs.Karabiner-DriverKit-VirtualHIDDeviceDaemon";
      serviceConfig.KeepAlive = true;
    };

    # # Normally karabiner_console_user_server calls activate on the manager but
    # # because we use a custom location we need to call activate manually.
    # launchd.user.agents.activate_karabiner_system_ext = {
    #   serviceConfig.ProgramArguments = [
    #     "${parentAppDir}/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"
    #     "activate"
    #   ];
    #   serviceConfig.RunAtLoad = true;
    # };
    # environment.etc."sudoers.d/kanata".source = pkgs.runCommand "sudoers-kanata" { } ''
    #   KANATA_BIN="${pkgs.kanata}/bin/kanata"
    #   SHASUM=$(sha256sum "$KANATA_BIN" | cut -d' ' -f1)
    #   cat <<EOF >"$out"
    #   %admin ALL=(root) NOPASSWD: sha256:$SHASUM $KANATA_BIN
    #   EOF
    # '';

    # # NOTE: this is quite ugly... Since this part is *not* handled by Nix.
    #
    # launchd.daemons.karabiner-driverkit = {
    #   serviceConfig = {
    #     ProgramArguments = [
    #       "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
    #     ];
    #     KeepAlive = true;
    #     ProcessType = "Interactive";
    #   };
    # };

    # TODO: make this a user agent.
    launchd.daemons.kanata = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.kanata}/bin/kanata"
          "-c"
          "${configFile}"
        ];
        # NOTE: this allows ctrl + space + esc to be used as an escape hatch.
        KeepAlive = false;
        RunAtLoad = true;
      };
    };
  };
}
