{ config, ... }: {
  hardware = {
    graphics.enable = true;
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