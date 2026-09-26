{ flake, pkgs, utils, lib, ... }: {
  virtualisation.xen.machines = {
    letta-code = {
      modules = [
        flake.nixosModules.optionals
        flake.nixosModules.basic
        flake.inputs.impermanence.nixosModules.impermanence
        flake.inputs.letta-code.nixosModules.letta-code
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
        mac = "FE:FF:FF:00:00:04";
        ip = "10.135.116.13";
      };
      disks.xvdb = {
        # sudo qemu-img create -f qcow2 -o compression_type=zstd,nocow=on letta-code.qcow2 32G
        target = "/mnt/asm/@vm/images/letta-code.qcow2";
        format = "qcow2";
      };
      extraXenlight = ''
        memory=4096
        vcpus=4
        cpu_weight=128
      '';
    };
  };
}
