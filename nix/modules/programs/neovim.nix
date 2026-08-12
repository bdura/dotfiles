# # Neovim
#
# Neovim with the full toolchain of LSPs, formatters, and renderers
# baked into its runtime PATH. Configuration itself is out of scope:
# it is managed as plain dotfiles outside Nix.
{
  lib,
  pkgs,
  wrappers,
  config,
  ...
}:
with lib; let
  cfg = config.my.programs.neovim;
  reflow = pkgs.rustPlatform.buildRustPackage rec {
    pname = "reflow";
    version = "0.1.0";
    src = fetchGit {
      url = "https://codeberg.org/bdura/reflow";
      rev = "e2d6fc242fa3cb01b5ed23b285bcf43663d87745";
    };
    cargoLock.lockFile = "${src}/Cargo.lock";
    nativeBuildInputs = with pkgs; [git];
  };
  nvim = wrappers.lib.wrapPackage {
    pkgs = pkgs;
    package = pkgs.neovim-unwrapped;
    binName = "nvim";
    runtimeInputs = with pkgs; [
      # Fuzzy-finding
      fzf
      ripgrep
      fd

      # Git integration
      git
      git-lfs
      lazygit

      # Various build tools
      lua
      luarocks
      tree-sitter

      # LSPs for ubiquitous languages
      nixd
      rumdl
      taplo
      yaml-language-server
      bash-language-server
      vscode-json-languageserver
      typos-lsp

      # Formatters for ubiquitous languages
      shfmt
      nixfmt
      alejandra
      yamlfmt
      jq
      reflow

      # Render tools
      imagemagick # Image conversion
      ghostscript # PDF files
      tectonic # Render LaTeX expressions
      mermaid-cli # Render mermaid diagrams
      # latexmk
      # bibtex
      biber
    ];
  };
in {
  options.my.programs.neovim = {
    enable = mkEnableOption "Neovim with shared LSP/formatter toolchain";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [nvim];

    environment.variables = let
      bin = "${nvim}/bin/nvim";
    in {
      EDITOR = bin;
      MANPAGER = "${bin} --cmd 'set laststatus=0 ' +'set statuscolumn= nowrap laststatus=0' +Man\\!";
    };
  };
}
