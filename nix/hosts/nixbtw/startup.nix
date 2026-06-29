{...}: {
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

  # Register Hyprland as a system-level Wayland session so the
  # noctalia-greeter session picker can discover it. The user-level
  # Hyprland config still lives in home-manager.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
}
