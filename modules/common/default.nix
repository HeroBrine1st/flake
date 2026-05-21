{ lib, ...}: {
  imports = [
    ./nix.nix
    ./cli
    ./network/overlay
    ./scrutiny-collector.nix
    ./syncthing.nix
  ];

  options = {
    boot.isBareMetal = lib.mkOption {
      description = "Boolean option to declare availability of direct hardware access on current machine";
      type = lib.types.bool;
      default = true;
    };
  };
}