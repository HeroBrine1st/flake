{ flake, pkgs, utils, lib, ... }: {
  virtualisation.xen.machines = {
    general = {
      modules = [
        flake.nixosModules.optionals
        flake.nixosModules.basic
        flake.inputs.impermanence.nixosModules.impermanence
        ./guest.nix
        {
          fileSystems."/nix" = {
            device = "/dev/xvdb";
            fsType = "btrfs";
            options = [ "defaults" ];
          };
          boot.initrd.systemd = {
            storePaths = [ pkgs.btrfs-progs pkgs.libuuid ];
            services.mkbtrfs = rec {
              unitConfig.DefaultDependencies = false;
              requiredBy = [
                "${utils.escapeSystemdPath "/sysroot/nix"}.mount"
              ];
              before = requiredBy;
              requires = [
                "${utils.escapeSystemdPath "/dev/xvdb"}.device"
              ];
              after = requires;
              serviceConfig.Type = "oneshot";
              script = ''
                set -euo pipefail
                if [[ -z "$(${lib.getExe' pkgs.libuuid "blkid"} -s TYPE -o value /dev/xvdb)" ]]; then
                  echo "Creating btrfs filesystem"
                  ${lib.getExe' pkgs.btrfs-progs "mkfs.btrfs"} /dev/xvdb
                fi
              '';
            };
          };
        }
      ];
      networking.bridges.xenbr0 = {
        mac = "FE:FF:FF:00:00:03";
        ip = "10.135.116.12";
      };
      disks.xvdb = {
        target = "/dev/asm/general";
        format = "raw";
      };
      extraXenlight = ''
        memory=8192
        vcpus=8
        cpu_weight=256
      '';
    };
  };
}