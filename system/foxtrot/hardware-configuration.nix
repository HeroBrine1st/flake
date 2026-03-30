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
    kernelParams = [ "intel_iommu=on" ];
  };

  # same_cpu_crypt disables encryption workqueue, gains are unknown
  environment.etc.crypttab.text = ''
    romeo-papa-bravo PARTLABEL=ROMEO-PAPA-BRAVO /nix/persist/keyfile/romeo-papa-bravo.key nofail
    romeo-papa-alfa  PARTLABEL=ROMEO-PAPA-ALFA  /nix/persist/keyfile/romeo-papa-alfa.key  nofail
    sierra-mike-alfa PARTLABEL=SIERRA-MIKE-ALFA /nix/persist/keyfile/sierra-mike-alfa.key discard,no-read-workqueue,no-write-workqueue
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
      device = "/dev/disk/by-uuid/90D7-188B";
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
    # /var/lib/docker moved to impermanence
    # /var/docker_data moved to impermanence
    "/mnt/brp" = { # bravo-romeo-papa
      device = "/dev/mapper/romeo-papa-bravo";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "autodefrag" "noatime" "nofail" "x-systemd.before=local-fs.target" ];
    };
    "/mnt/arp" = {
      device = "UUID=9ca297fe-888c-452f-a640-b68f4b641ed1"; # multi-device filesystem
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" "noatime" "nofail" "x-systemd.before=local-fs.target" ];
    };
  };

  networking.hostName = "foxtrot";
  networking.networkmanager.enable = true;

  environment.etc."systemd/network/99-default.link.d/wake-on-lan.conf".text = ''
    [Link]
    WakeOnLan=magic
  '';

  system.checks = [
    (pkgs.runCommand "check-systemd-link-unit-presence" {} ''
      test -f "${config.systemd.package}/lib/systemd/network/99-default.link"
      touch $out
    '')
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
}
