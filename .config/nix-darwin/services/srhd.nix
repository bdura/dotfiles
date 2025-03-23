{
  pkgs,
  config,
  ...
}:
let
  srhd = pkgs.callPackage ../packages/srhd.nix { };
in
{
  launchd.user.agents.srhd = {
    path = [ config.environment.systemPath ];
    serviceConfig = {
      ProgramArguments = [
        "${srhd}/bin/srhd"
      ];
      KeepAlive = true;
      StandardOutPath = /tmp/srhd.out;
      StandardErrorPath = /tmp/srhd.err;
    };
  };
}
