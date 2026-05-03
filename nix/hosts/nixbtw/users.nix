{
  pkgs,
  username,
  ...
}: let
  inherit (import ./variables.nix) gitUsername;
in {
  users.users = {
    "${username}" = {
      homeMode = "755";
      isNormalUser = true;
      description = "${gitUsername}";
      # NOTE: on first login, use this password.
      # Then, immediately create a file containing the hash for the *actual* password
      # (see below)
      initialHashedPassword = "$y$j9T$u9Vi2s3/fJru5y48CgYCl/$ZXrpSMA72ziaeJL0ZzqrLFQl4kTs1ScI5YvRs8sfGeA";
      hashedPasswordFile = "/etc/secrets/basile-password-hash";
      extraGroups = [
        "networkmanager"
        "wheel"
        "libvirtd"
        "scanner"
        "lp"
        "uinput"
      ];
      shell = pkgs.fish;
      ignoreShellProgramCheck = true;
      packages = [];
    };
  };
}
