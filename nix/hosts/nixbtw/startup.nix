{
  pkgs,
  username,
  ...
}: {
  boot = {
    # Bootloader.
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      # Disable generation selection by default. Press any key to re-enable it.
      timeout = 0;
    };
    # Make /tmp a tmpfs
    tmp = {
      useTmpfs = true;
      cleanOnBoot = true;
      # The Tmpfs can use 30% of available RAM at most
      tmpfsSize = "30%";
    };
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16 * 1024; # 16 GiB
    }
  ];

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # Wayland Desktop Manager is installed only via home-manager!
        user = username;
        # start Hyprland with a TUI login manager
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
      };
    };
  };
}
