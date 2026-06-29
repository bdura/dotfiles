{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.noctalia.nixosModules.default
    inputs.noctalia-greeter.nixosModules.default
  ];

  programs.noctalia = {
    enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
    systemd.enable = false;
    recommendedServices.enable = true;
  };

  # noctalia-greeter scans `share/wayland-sessions/*.desktop` on the
  # system path to populate its session picker. NixOS' system-path only
  # links the directories listed in `environment.pathsToLink`, and
  # `wayland-sessions` isn't included by default — without this the
  # picker only sees the fallback Shell session.
  environment.pathsToLink = ["/share/wayland-sessions"];

  programs.noctalia-greeter = {
    enable = true;
    package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;

    greeter-args = "--session Hyprland";
    settings = {
      cursor = {
        theme = "Adwaita";
        size = 24;
      };
      keyboard = {
        layout = "us";
      };
    };
  };
}
