{
  # Git Configuration ( For Pulling Software Repos )
  gitUsername = "Basile Dura";
  gitEmail = "basile@bdura.me";

  # Hyprland Settings
  extraMonitorSettings = ''
    $dotblocksLGScreen = LG Electronics LG HDR 4K 0x00025CD8
    $homeScreen = Samsung Electric Company LS27D80xU HNAX400122

    # See https://wiki.hyprland.org/Configuring/Monitors/
    monitor = eDP-1,preferred,auto,1
    monitor = desc:$dotblocksLGScreen,preferred,auto-up,1
    monitor = desc:$homeScreen,preferred,auto-left,1
    # Uncomment next line to mirror eDP-1
    monitor = ,preferred,auto-up,1
    # monitor = , preferred, auto, 1, mirror, eDP-1
  '';

  # Waybar Settings
  clock24h = true;

  # Program Options
  browser = "firefox"; # Set Default Browser (google-chrome-stable for google-chrome)
  terminal = "kitty"; # Set Default System Terminal

  keyboardLayout = "us";
  keyboardVariant = "mac";
}
