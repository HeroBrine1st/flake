{ pkgs, ... }: {
  imports = [
    ./packages.nix
    ./aliases.nix
    ./nix.nix

    ./bash
    ./zsh
  ];
}