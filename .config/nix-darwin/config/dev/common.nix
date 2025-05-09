{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
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
