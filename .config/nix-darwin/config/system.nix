# # "System" configuration
#
# Uses different `nix-darwin` options to configure the machine.

{ ... }:
{
  time.timeZone = "Europe/Paris";

  security.pam.services.sudo_local.touchIdAuth = true;

  system.startup.chime = false;
  system.defaults = {
    screencapture.target = "clipboard";
    # Faster transitions
    # universalaccess.reduceMotion = true;
    loginwindow.GuestEnabled = false;
    # Each display has its own spaces
    spaces.spans-displays = false;
    menuExtraClock = {
      Show24Hour = true;
      ShowSeconds = true;
    };
    finder = {
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleInterfaceStyle = "Dark";
      "com.apple.mouse.tapBehavior" = 1;
      # Natural scroll direction
      "com.apple.swipescrolldirection" = true;
      NSAutomaticSpellingCorrectionEnabled = false;
      # Auto-hide menu bar. Useful if we use sketchybar
      _HIHideMenuBar = false;
      KeyRepeat = 2;
    };
    trackpad = {
      TrackpadThreeFingerDrag = true;
      # tap to click
      Clicking = true;
      # two-finger-tap right click
      TrackpadRightClick = true;
    };
    # Disable most recently used apps in the dock
    dock.mru-spaces = false;
  };
}
