# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix")
    ./hardware-mitigations.nix
  ];

  boot = {
    kernelModules = [ "kvm-amd" "lm75" "nct6775" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "usbhid" ];
      luks.devices = {
        "root" = {
          device = "/dev/disk/by-uuid/e0a78f05-e0b6-4fbb-bf07-08b432b291d5";
          allowDiscards = true;
        };
      };
    };
  };

  environment.etc.crypttab.text = ''
    hdd PARTLABEL=HDD /etc/keyfile/hdd.key nofail
    ssd PARTLABEL=SSD /etc/keyfile/ssd.key allow-discards
  '';

  fileSystems = {
    "/" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@nix" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/D6F2-4688";
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
      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@home-nix" ];
    };
#    "/var/cache" = {
#      device = "/dev/mapper/root";
#      fsType = "btrfs";
#      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@var_cache" ];
#    };
#    "/var/log" = {
#      device = "/dev/mapper/root";
#      fsType = "btrfs";
#      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@var_log" ];
#    };
#    "/var/run" = {
#      device = "/dev/mapper/root";
#      fsType = "btrfs";
#      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@var_run" ];
#    };
#    "/var/tmp" = {
#      device = "/dev/mapper/root";
#      fsType = "btrfs";
#      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@var_tmp" ];
#    };
#    "/var/lib/docker" = {
#      device = "/dev/mapper/root";
#      fsType = "btrfs";
#      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@var_lib_docker" ];
#    };
    "/mnt/extra" = {
      device = "/dev/mapper/ssd";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" "subvol=@user" ];
    };
    "/mnt/extra/.fsroot" = {
      device = "/dev/mapper/ssd";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" ];
    };
    "/mnt/hdd" = {
      device = "/dev/mapper/hdd";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "autodefrag" "subvol=@user" ];
    };
    "/mnt/hdd/.fsroot" = {
      device = "/dev/mapper/hdd";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "autodefrag" ];
    };
    "/mnt/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "rw" "noexec" "nodev" "nosuid" "uid=1000" "gid=1000" "mode=1700" ];
    };
#    "/home/herobrine1st/.cache" = {
#      device = "/var/cache/user/1000";
#      fsType = "none";
#      options = [ "defaults" "bind" ];
#    };
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.end1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    # Enable OpenGL
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      vaapiVdpau
    ];
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
	  # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  boot.extraModprobeConfig = ''
    options nvidia NVreg_TemporaryFilePath=/var/tmp
  '';

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.xpadneo.enable = true;

#  environment.sessionVariables = rec {
#    LIBVA_DRIVER_NAME=nvidia
#    MOZ_X11_EGL=1
#    __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
#    NVD_BACKEND=direct MOZ_DISABLE_RDD_SANDBOX=1
#  };
}
