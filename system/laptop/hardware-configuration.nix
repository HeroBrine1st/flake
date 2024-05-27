{ config, lib, pkgs, modulesPath, ... }: {

  # TODO disko

  hardware.enableRedistributableFirmware = true;

  boot = {
    kernelModules = [ "kvm-amd" ];
    loader = {
      systemd-boot.enable = true;
      systemd-boot.consoleMode = "auto";
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "rtsx_usb_sdmmc" ];
      kernelModules = [ "amdgpu" ];
      luks.devices = {
        "root" = {
          device = "/dev/disk/by-uuid/e0a78f05-e0b6-4fbb-bf07-08b432b291d5"; # TODO
          allowDiscards = true;
        };
      };
    };
  };

  networking.hostName = "MOBILE-DCV5AQD";
  networking.networkmanager.enable = true;
#  networking.useDHCP = true; looks like not needed

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
    ];
  };

  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  hardware.xpadneo.enable = true;
}
