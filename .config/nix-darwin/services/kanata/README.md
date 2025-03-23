# Kanata on macOS

Kanata is a quite powerful keyboard remapper. Unfortunately, the installation process
using Nix has been extremely tedious, and as of yet still hinges on manual steps.

## Installation

1. Install [Karabiner's Virtual HID driver][karabiner], using the installer.
   Then, you will need to run the following post installation step:

   ```shell
   /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
   ```

   The other step listed in the [README][karabiner-readme] is handled by nix.

2. Run `darwin-rebuild` to install and configure kanata. If not prompted to do so,
   allow input monitoring to your `kanata` installation

## Todos

We can obviously do better, first and foremost by managing the installation of
the driver within nix directly.

Reading list:

- [nix derivation for Karabiner-Elements][karabiner-elements] (includes the DriverKit)
- [karabiner-elements service][karabiner-service]

[karabiner]: https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice
[karabiner-readme]: https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice?tab=readme-ov-file#usage
[karabiner-elements]: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/ka/karabiner-elements/package.nix#L63
[karabiner-service]: https://github.com/LnL7/nix-darwin/blob/ebb88c3428dcdd95c06dca4d49b9791a65ab777b/modules/services/karabiner-elements/default.nix
