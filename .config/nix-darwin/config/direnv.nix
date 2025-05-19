# # `direnv` configuration
#
# For some reason the `silent` option does not work with `direnv`,
# hence I am resorting to adding a `direnv.toml` file in `$DIRENV_CONFIG`
# (ie `/etc/direnv/`).

{
  ...
}:
{
  programs = {
    direnv = {
      enable = true;
      # silent = true;
    };
  };

  environment.etc."direnv/direnv.toml".text = ''
    [global]
    hide_env_diff = true
  '';
}
