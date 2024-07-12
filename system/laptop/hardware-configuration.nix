{ config, lib, pkgs, ... }: {

  disko.devices = {
    disk = {
      system = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "luks";
                name = "root";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [ "defaults" "compress=zstd" "discard=async" ];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "defaults" "compress=zstd" "discard=async" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
      extra = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            root = {
              size = "100%";
              content = {
                type = "luks";
                name = "extra";
                passwordFile = "/nix/persist/extra.key";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "@user" = {
                      mountpoint = "/mnt/extra";
                      mountOptions = [ "defaults" "compress=zstd" "discard=async" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=25%" "mode=755" ];
    };
    "/nix" = {
      neededForBoot = true;
    };
    "/.fsroot" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" "nofail" ];
    };
    "/mnt/extra/.fsroot" = {
      device = "/dev/mapper/extra";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "discard=async" "nofail" ];
    };
  };

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
    };
  };

  networking.hostName = "MOBILE-DCV5AQD";
  networking.networkmanager.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd # OpenCL
    ];
  };

  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  hardware.xpadneo.enable = true;
}
