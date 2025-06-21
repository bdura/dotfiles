{
  pkgs,
  ...
}:
{
  services.skhd = {
    enable = true;
    package = pkgs.skhd;
    skhdConfig = [
      "control + option + shift - return : open -n '/Applications/Nix Trampolines/Ghostty.app'"
    ];
  };
}
