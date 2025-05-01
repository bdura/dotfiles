{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    git
    git-lfs
    lazygit
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
