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
              requiredBy = [
                "${utils.escapeSystemdPath "/sysroot/nix"}.mount"
              ];
              before = requiredBy;
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
        # sudo qemu-img create -f qcow2 -o compression_type=zstd,nocow=on forgejo-runner.qcow2 256G
        # nix-shell -p libguestfs-with-appliance --run zsh
        # sudo guestfish -a forgejo-runner.qcow2
        # run
        # mkfs ext4 /dev/sda
        # Ctrl-D
        target = "/mnt/asm/@vm/images/general.qcow2";
        format = "qcow2";
      };
      extraXenlight = ''
        memory=8192
        vcpus=8
        cpu_weight=256
      '';
    };
  };
}