{ pkgs, ... }: {
  imports = [
    ./packages.nix
    ./oh-my-bash.nix
  ];
}