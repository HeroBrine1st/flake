{ rootDevice ? "/dev/xvdb", lib, pkgs, utils, ... }: let
in {
  fileSystems."/nix" = {
    device = rootDevice;
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
        "${utils.escapeSystemdPath rootDevice}.device"
      ];
      after = requires;
      serviceConfig.Type = "oneshot";
      script = ''
        set -euo pipefail
        if [[ -z "$(${lib.getExe' pkgs.libuuid "blkid"} -s TYPE -o value ${rootDevice})" ]]; then
          echo "Creating btrfs filesystem"
          ${lib.getExe' pkgs.btrfs-progs "mkfs.btrfs"} ${rootDevice}
        fi
      '';
    };
  };
}