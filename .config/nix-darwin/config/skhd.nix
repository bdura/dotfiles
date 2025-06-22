{
  pkgs,
  ...
}:
{
  services.skhd = {
    enable = false;
    package = pkgs.skhd;
    skhdConfig = ''
      control + option + shift - return : open -n '/Applications/Nix Trampolines/Ghostty.app'
      cmd + shift - return : wezterm cli spawn --new-window || open '/Applications/Nix Trampolines/WezTerm.app'
    '';
  };
}
