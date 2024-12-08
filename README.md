# Configurations

This repo contains the configuration files for my system, which I manage with GNU Stow.

## Installation

Check out this directory within `$HOME`:

```shell
git clone git@github.com:bdura/dotfiles.git $HOME/.dotfiles
```

Then use GNU Stow to create symlinks:

```shell
cd $HOME/.dotfiles
stow .
```

## NixOS

I'm using NixOS on my work laptop - every aspect is managed within the [`nix`](./nix) folder.
For now it's basically a "fork" of the great [ZaneyOS project](https://gitlab.com/Zaney/zaneyos).

## To dos

- [ ] manage Firefox extensions using Nix
