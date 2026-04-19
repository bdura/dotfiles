{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  buildInputs = with pkgs; [
    stow
    kdlfmt
    lua-language-server
  ];
}
