# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }: let
  libmali = (pkgs.callPackage ../../packages/libmali.nix {});
in {
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
        };
      };
    };
  };

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
      device = "/dev/disk/by-uuid/1f0da7fa-b215-4d25-9d57-a91744a5589c";
      fsType = "ext4";
      options = [ "defaults" "nofail" ];
    };
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.end1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

#  environment.systemPackages = [
#    libmali.libmali-valhall-g610
#  ];
#
#  hardware.firmware = [
#    libmali.mali-firmware-g610
#  ];

  # hardware.opengl.enable = true;

#  services.udev.extraRules = ''
#    KERNEL=="mpp_service", MODE="0660", GROUP="video"
#    KERNEL=="rga", MODE="0660", GROUP="video"
#    KERNEL=="system", MODE="0666", GROUP="video"
#    KERNEL=="system-dma32", MODE="0666", GROUP="video"
#    KERNEL=="system-uncached", MODE="0666", GROUP="video"
#    KERNEL=="system-uncached-dma32", MODE="0666", GROUP="video" RUN+="${pkgs.coreutils}bin/chmod a+rw /dev/dma_heap"
#  '';

}
