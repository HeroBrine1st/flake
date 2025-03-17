{ lib, config, ... }: {
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

#  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_blk" ];

  disko.devices.disk = {
    root = {
      device = "/dev/vda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          "reserved" = { # for grub in legacy mode
            size = "1M";
            type = "EF02";
          };
          boot = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              mountpoint = "/.fsroot";
              subvolumes = {
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
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
    "/nix".neededForBoot = true;
  };

  systemd.network.enable = true;
  networking.useDHCP = false; # static condiguration provided in impermanence.nix
  networking.hostName = "bravo";
  nixpkgs.hostPlatform = "x86_64-linux";
}