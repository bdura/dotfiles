{ unstable, ... }:
{
  environment.systemPackages = with unstable; [
    git
    lazygit
    serie
    delta
  ];
}
