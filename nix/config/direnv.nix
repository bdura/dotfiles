{
  pkgs,
  ...
}:
let
  direnv-exec = pkgs.writeShellScriptBin "direnv-exec" ''
    direnv exec . "$@"
  '';
in
{
  programs = {
    direnv = {
      enable = true;
      silent = true;
    };
  };

  environment.systemPackages = [
    direnv-exec
  ];
}
