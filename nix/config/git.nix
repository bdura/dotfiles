{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    lazygit
    serie
    delta
  ];
}
