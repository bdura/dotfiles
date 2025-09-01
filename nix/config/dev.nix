{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    neovim-unwrapped

    # Requirements for plugins
    nodejs
    python313
    clang
    rustup

    unzip

    zoxide
    zellij
    atuin
    starship
    bat
    eza
    fd
    fzf
    htop
    jq
    ripgrep
    tmux

    tlrc
  ];

  environment.variables.EDITOR = "nvim";
}
