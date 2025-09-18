{ pkgs, ... }: {
  imports = [
    ./packages.nix
    ./aliases.nix
    ./nix.nix

    ./zsh
  ];

  users.defaultUserShell = pkgs.zsh;
}