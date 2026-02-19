{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    helix
    neovim-unwrapped
    opencode

    # Requirements for plugins
    python313
    clang
    rustup
    nixfmt
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
    tomlq
    tree-sitter

    tlrc
  ];

  environment.variables = {
    EDITOR = "nvim";
    MANPAGER = "nvim +Man!";
  };
}
