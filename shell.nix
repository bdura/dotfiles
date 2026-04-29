{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    stow
    nixd
    nixfmt
    kdlfmt
    stylua
    alejandra
    kdlfmt
    lua-language-server
  ];
}
