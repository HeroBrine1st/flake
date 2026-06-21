{ pkgs, lib, config, ... }: let
  nvidia-driver = config.hardware.nvidia.package;
in {
  hardware = {
    graphics.enable = true;
    nvidia-container-toolkit.enable = true;
    nvidia = {
      open = true;
      modesetting.enable = true;
      nvidiaSettings = false;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  nixpkgs.allowedUnfreePackages = [
    "nvidia-x11"
  ];
}