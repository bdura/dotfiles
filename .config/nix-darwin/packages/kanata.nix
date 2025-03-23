{
  pkgs,
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "kanata";
  version = "1.8.0";

  buildInputs = [
    pkgs.llvmPackages_19.libcxxClang
  ];

  src = fetchFromGitHub {
    owner = "jtroo";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-RTFP063NGNfjlOlZ4wghpcUQEmmj73Xlu3KPIxeUI/I=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-/r4u7pM7asCvG3LkbuP1Y63WVls1uZtV/L3cSOzUXr4=";

  meta = {
    description = "Improve keyboard comfort and usability with advanced customization ";
    homepage = "https://github.com/jtroo/kanata";
  };
}
