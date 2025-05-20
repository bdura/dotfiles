{ ... }:
{
  programs.direnv = {
    enable = true;
  };

  environment.etc."direnv/direnv.toml".text = ''
    [global]
    hide_env_diff = true
  '';
}
