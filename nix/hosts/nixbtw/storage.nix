# Storage layout for nixbtw.
#
# Partitioning, encryption (LUKS) and btrfs subvolumes are declared
# through disko (<https://github.com/nix-community/disko>), which
# generates both the install-time formatting scripts and the matching
# `fileSystems.*` entries from a single source of truth.
#
# The swapfile entry below is a stock NixOS `swapDevices` declaration;
# it lives here (rather than in `config.nix`) because it is tightly
# coupled to the dedicated `@swap` subvolume defined in `disko.devices`.
#
# To (re)format the disk from a NixOS installer, run — DESTRUCTIVE,
# wipes /dev/nvme0n1:
#
#     sudo nix --experimental-features 'nix-command flakes' run \
#       github:nix-community/disko/latest -- \
#       --mode destroy,format,mount \
#       --flake .#nixbtw
{
  # swapfile lives on the dedicated @swap subvolume defined below
  # (nodatacow is a btrfs prerequisite for swapfiles).
  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16 * 1024; # 16 GiB
    }
  ];

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
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
                      mountpoint = "/swap";
                      mountOptions = [
                        "nodatacow"
                        "noatime"
                        "nodev"
                        "nosuid"
                        "noexec"
                      ];
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
