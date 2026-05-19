{
  pkgs,
  wrappers,
  ...
}: let
  claude = wrappers.lib.wrapPackage {
    pkgs = pkgs;
    package = pkgs.claude-code;
    binName = "claude";
    env = {
      CLAUDE_CONFIG_DIR = "$HOME/.config/claude";
    };
  };
  vibe = wrappers.lib.wrapPackage {
    pkgs = pkgs;
    package = pkgs.mistral-vibe;
    binName = "vibe";
    env = {
      VIBE_HOME = "$HOME/.config/vibe";
    };
  };
in {
  # Skip pint's test suite — it pulls in pytest-benchmark and runs a
  # multi-minute benchmark phase whenever mistral-vibe's closure is
  # rebuilt from source.
  nixpkgs.overlays = [
    (_final: prev: {
      pythonPackagesExtensions =
        prev.pythonPackagesExtensions
        ++ [
          (_pyfinal: pyprev: {
            pint = pyprev.pint.overridePythonAttrs (_: {doCheck = false;});
          })
        ];
    })
  ];

  environment.systemPackages = [
    pkgs.opencode
    claude
    vibe

    # Tools
    pkgs.rtk
  ];
}
