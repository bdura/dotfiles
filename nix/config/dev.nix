{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    neovim-unwrapped

    # Requirements for plugins
    nodejs
    python313
    clang
    rustup
    nixfmt-rfc-style
    lua
    luarocks

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

  environment.variables = {
    EDITOR = "nvim";
    MANPAGER = "nvim +Man!";
  };
}
