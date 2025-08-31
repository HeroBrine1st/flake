{ pkgs, ... }: {
  imports = [
    ./packages.nix
    ./aliases.nix
    ./nix.nix

    ./oh-my-bash.nix
    ./zsh
  ];
}