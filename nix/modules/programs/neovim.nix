# # Neovim
#
# Neovim with the full toolchain of LSPs, formatters, and renderers
# baked into its runtime PATH. Configuration itself is out of scope:
# `init.lua` and friends are managed as plain dotfiles outside Nix,
# so this module installs the *unwrapped* upstream Neovim and lets
# the `wrappers` library inject every runtime dependency without
# polluting the system PATH.
#
# Group rationale (none of these are required by Neovim itself —
# they are tools that plugins shell out to):
#
# - Fuzzy-finding (`fzf`, `ripgrep`, `fd`): telescope / fzf-lua etc.
# - Git integration (`git`, `git-lfs`, `lazygit`): fugitive, gitsigns,
#   and the lazygit popup.
# - Build tools (`lua`, `luarocks`, `tree-sitter`): needed when
#   plugins compile something at install time.
# - LSPs for ubiquitous languages: Nix, Markdown, TOML, YAML, Bash.
#   Per-project LSPs (Rust, Python, ...) come in via direnv / project
#   shells, not here, so this set deliberately stays small.
# - Formatters mirror the LSP set so format-on-save works out of
#   the box for the same languages.
# - Render tools: `image.nvim` / preview plugins shell out to
#   `imagemagick` (raster), `ghostscript` (PDF), `tectonic` + `biber`
#   (LaTeX), `mermaid-cli` (diagrams).
#
# Also exports `EDITOR` and `MANPAGER` so non-Neovim callers (git,
# man, sudoedit, ...) pick up the same wrapped binary.
{
  lib,
  pkgs,
  wrappers,
  config,
  ...
}:
with lib; let
  cfg = config.my.programs.neovim;
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

      # Formatters for ubiquitous languages
      shfmt
      nixfmt
      alejandra
      yamlfmt

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
