{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "ef00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "encrypted";
                settings = {
                  allowDiscards = true; # for SSDs
                };
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-L"
                    "nixos"
                    "-f"
                  ];
                  subvolumes = {
                    "@root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "subvol=@root"
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "subvol=@nix"
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "subvol=@home"
                        "compress=zstd"
                      ];
                    };
                    "@var" = {
                      mountpoint = "/var";
                      mountOptions = [
                        "subvol=@var"
                        "compress=zstd"
                      ];
                    };
                    "@log" = {
                      mountpoint = "/var/log";
                      mountOptions = [
                        "subvol=@log"
                        "compress=zstd"
                        "nosuid"
                        "nodev"
                        "noexec"
                      ];
                    };
                    "@swap" = {
                      mountpoint = "none";
                      swap = {
                        size = "20G";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
