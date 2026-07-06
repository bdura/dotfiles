{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.noctalia.nixosModules.default];

  programs.noctalia = {
    enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
    systemd.enable = false;
    recommendedServices.enable = true;
  };
}
