{ config, lib, pkgs, modulesPath, ... }: {
  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "ehci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
      luks.devices = {
        "root" = {
          device = "/dev/disk/by-uuid/e332ee43-09fe-4100-a885-1bf81b3b5a0d";
          allowDiscards = true;
          bypassWorkqueues = true;
          keyFile = "/dev/disk/by-partlabel/root-keyfile";
          keyFileSize = 2048;
          fallbackToPassword = true;
        };
      };
    };
    kernelModules = [ "kvm-intel" ];
    loader = {
      systemd-boot.enable = true;
      systemd-boot.consoleMode = "auto";
      efi.canTouchEfiVariables = true;
    };
  };
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
      device = "/dev/disk/by-uuid/90D7-188B";
      fsType = "vfat";
    };
    "/.fsroot" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" ];
    };
    # /home moved to impermanence
    # /var/lib/docker moved to impermanence
    # /var/docker_data moved to impermanence
  };

  networking.hostName = "foxtrot";
  networking.networkmanager.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
}
