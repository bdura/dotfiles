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
in
{
  config = {
    environment.systemPackages = [ pkgs.kanata ];

    # environment.etc."sudoers.d/kanata".source = pkgs.runCommand "sudoers-kanata" { } ''
    #   KANATA_BIN="${pkgs.kanata}/bin/kanata"
    #   SHASUM=$(sha256sum "$KANATA_BIN" | cut -d' ' -f1)
    #   cat <<EOF >"$out"
    #   %admin ALL=(root) NOPASSWD: sha256:$SHASUM $KANATA_BIN
    #   EOF
    # '';

    # NOTE: this is quite ugly... Since this part is *not* handled by Nix.
    launchd.daemons.karabiner-driverkit = {
      serviceConfig = {
        ProgramArguments = [
          "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
        ];
        KeepAlive = true;
        ProcessType = "Interactive";
      };
    };

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
