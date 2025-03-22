{
  lib,
  pkgs,
  fetchurl,
  ...
}:

pkgs.stdenv.mkDerivation rec {
  pname = "karabiner-driverkit";
  version = "5.0.0";

  src = fetchurl {
    url = "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v${version}/Karabiner-DriverKit-VirtualHIDDevice-${version}.pkg";
    hash = "sha256-hKi2gmIdtjl/ZaS7RPpkpSjb+7eT0259sbUUbrn5mMc=";
  };

  nativeBuildInputs = with pkgs; [
    cpio
    xar
  ];

  unpackPhase = ''
    xar -xf $src
    ls
    zcat Payload | cpio -i
  '';

  # sourceRoot = ".";
  #
  # postPatch = ''
  #   shopt -s globstar
  #   for f in *.pkg/Library/**/Launch{Agents,Daemons}/*.plist; do
  #     substituteInPlace "$f" \
  #       --replace-fail "/Library/" "$out/Library/"
  #   done
  # '';

  installPhase = ''
    mkdir -p $out/driver
    cp -R Applications Library $out/driver
  '';

  meta = {
    changelog = "https://github.com/pqrs-org/Karabiner-Elements/releases/tag/v${version}";
    description = "Karabiner-Elements is a powerful utility for keyboard customization on macOS Ventura (13) or later";
    homepage = "https://karabiner-elements.pqrs.org/";
    license = lib.licenses.unlicense;
    maintainers = [ ];
    platforms = lib.platforms.darwin;
  };
}
