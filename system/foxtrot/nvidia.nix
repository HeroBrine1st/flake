{ pkgs, lib, config, ... }: let
  nvidia-driver = config.boot.kernelPackages.nvidiaPackages.latest;
in {
  hardware.nvidia-container-toolkit = {
    enable = true;
    isolate = true;
  };

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  nixpkgs.allowedUnfreePackages = [
    "nvidia-x11"
  ];
}