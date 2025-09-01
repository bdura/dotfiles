{ pkgs, username, ... }:

let
  inherit (import ./variables.nix) gitUsername;
in
{
  users.users = {
    "${username}" = {
      homeMode = "755";
      isNormalUser = true;
      description = "${gitUsername}";
      hashedPassword = "$y$j9T$SZ7yFA8sS4Lvg2pSZwzTi/$s0ungptwpl3KH64MmRXeOrsM9e/u785ngGD1r.5QY03";
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
      packages = [ ];
    };
  };
}
