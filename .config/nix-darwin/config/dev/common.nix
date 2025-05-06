{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    btop
    git
    git-lfs
    lazygit
    ripgrep
    fd
    stow
    jq
    yq
    pre-commit
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
