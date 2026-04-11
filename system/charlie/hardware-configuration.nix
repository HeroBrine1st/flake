{ lib, config, ... }: {
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  disko.devices.disk = {
    root = {
      device = "/dev/sda";
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
          nix = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
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
  networking.useDHCP = false; # is not read at all! Only emits warning if true with systemd-network
  systemd.network.wait-online.enable = false; # stuck at configuring; awaits static routes (not that I didn't add them...)

  networking.hostName = "charlie";
  nixpkgs.hostPlatform = "x86_64-linux";
}