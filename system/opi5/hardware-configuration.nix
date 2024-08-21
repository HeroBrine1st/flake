# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }: {
  imports = [];

  hardware.enableRedistributableFirmware = true;

  boot = {
    kernelParams = [
      "usb-storage.quirks=0x0bc2:0xaa15:u"
    ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      availableKernelModules = ["nvme"];
      kernelModules = [];
      luks.devices = {
        "root" = {
          device = "/dev/disk/by-uuid/c5e66bf4-f786-4b59-af76-1286766d2d50";
          allowDiscards = true;
          keyFile = "/dev/mmcblk1";
          keyFileSize = 2048;
          fallbackToPassword = true;
        };
      };
    };
  };

  environment.etc.crypttab.text = ''
    basic PARTLABEL=BASIC /etc/keyfile/basic.key nofail
  '';


  fileSystems = {
    "/" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/C9F0-41F7";
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
    "/var/log" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@var_log" ];
    };
    "/var/run" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@var_run" ];
    };
    "/var/tmp" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@var_tmp" ];
    };
    "/var/lib/docker" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@var_lib_docker" ];
    };
    "/var/docker_data" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@docker_data" ];
    };
    "/mnt/basic" = {
      device = "/dev/mapper/basic";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "autodefrag" "nofail" "noatime" "subvol=@" ];
    };
    "/mnt/basic/Downloads/Movies" = {
      device = "/dev/mapper/basic";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "autodefrag" "nofail" "noatime" "subvol=@movies" ];
    };
    "/mnt/basic/.docker_data" = {
      device = "/dev/mapper/basic";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "autodefrag" "nofail" "noatime" "subvol=@docker_data" ];
    };
    "/mnt/basic/.fsroot" = {
      device = "/dev/mapper/basic";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "autodefrag" "nofail" "noatime" ];
    };
  };

  networking.hostName = "opi5";
  networking.networkmanager.enable = true;

  nixpkgs.hostPlatform = "aarch64-linux";

  services.udev.extraRules = ''
    KERNEL=="mpp_service", MODE="0660", GROUP="video"
    KERNEL=="rga", MODE="0660", GROUP="video"
    KERNEL=="system", MODE="0666", GROUP="video"
    KERNEL=="system-dma32", MODE="0666", GROUP="video"
    KERNEL=="system-uncached", MODE="0666", GROUP="video"
    KERNEL=="system-uncached-dma32", MODE="0666", GROUP="video", RUN+="${pkgs.coreutils}/bin/chmod a+rw /dev/dma_heap"
  '';

}
