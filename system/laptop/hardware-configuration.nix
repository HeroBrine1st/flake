{ config, lib, pkgs, ... }: {
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
          device = "/dev/disk/by-uuid/1b1c44b5-cca0-42dc-a6ab-94f8e49b0617";
          allowDiscards = true;
        };
      };
    };
  };

  environment.etc.crypttab.text = ''
    extra PARTLABEL=EXTRA /nix/persist/password/extra.key allow-discards,nofail
  '';

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=25%" "mode=755" ];
    };
    "/nix" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@nix" ];
      neededForBoot = true;
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/16B4-C9D3";
      fsType = "vfat";
    };
    "/.fsroot" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" ];
    };
    "/home" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@home" ];
    };
    "/mnt/extra" = {
      device = "/dev/mapper/extra";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@user" "nofail" ];
    };
    "/mnt/extra/.fsroot" = {
      device = "/dev/mapper/extra";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" "nofail" ];
    };
  };

  hardware.enableRedistributableFirmware = true;

  networking.hostName = "MOBILE-DCV5AQD";
  networking.networkmanager.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd # OpenCL
    ];
  };

  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  hardware.xpadneo.enable = true;
}
