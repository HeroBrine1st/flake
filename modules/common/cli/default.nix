{ pkgs, ... }: {
  imports = [
    ./packages.nix
    ./aliases.nix
    ./oh-my-bash.nix
    ./nix.nix
  ];
}