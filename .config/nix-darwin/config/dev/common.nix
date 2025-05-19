{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    bat
    btop
    ripgrep
    fd
    stow
    jq
    yq
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
