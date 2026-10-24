{ host, nix-store-disk, machine }: { lib, utils, pkgs, config, options, ... }@guest: lib.mkMerge [
  {
    networking.hostName = lib.mkDefault machine.name;
    nixpkgs = { inherit (host) pkgs; };
    system = lib.mkDefault { inherit (host.config.system) stateVersion; };
    boot = {
      kernelParams = [ "console=hvc0" ]; # SYSTEMD_SULOGIN_FORCE=1
      initrd.systemd.enable = true;
    };
    nix.enable = lib.mkDefault false;
  }
  (lib.mkIf (options.boot ? isBareMetal) { # for reusage
    boot.isBareMetal = false;
  })
  (lib.mkIf (!config.nix.enable) {
    fileSystems."/nix/store" = {
      device = "/dev/${nix-store-disk}";
      fsType = "erofs";
      options = [ "defaults" "ro" ];
    };
  })
  (lib.mkIf config.nix.enable {
    nix = {
      channel.enable = false;
      settings.experimental-features = [ "flakes" "nix-command" ];
      nixPath = [
        "nixpkgs=flake:nixpkgs"
      ];
    };

    boot = {
      initrd = {
        supportedFilesystems = [ "erofs" "overlay" ];
        # overlayfs is special case: it doesn't insert module like erofs does
        # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/tasks/filesystems/erofs.nix
        availableKernelModules = [ "overlay" ];
        systemd = {
          storePaths = [
            config.nix.package.out
            pkgs.findutils
          ];

          services.copy-nix-store = rec {
            unitConfig = {
              RequiresMountsFor = [
                "/sysroot/nix/store"
              ];
            };

            requiredBy = [
              "initrd-find-nixos-closure.service"
            ];
            before = requiredBy;

            serviceConfig.Type = "oneshot";

            script = ''
              set -euo pipefail

              mkdir -p /tmp/ro-store{-base,-upper,-work,}
              mount -t erofs -o defaults,ro /dev/${nix-store-disk} /tmp/ro-store-base

              # make store writable because nix-store --query wants to write to /nix/store/.links even with read-only=true
              # and this was written before I realized it needs a database, so we need to write a database
              # it's perhaps possible to TODO make all those things in derivation, though this works so another day
              mount -t overlay overlay \
                -o lowerdir=/tmp/ro-store-base,upperdir=/tmp/ro-store-upper,workdir=/tmp/ro-store-work \
                /tmp/ro-store

              SYSTEM="$(cat /tmp/ro-store/toplevel)"
              if ! [[ -e "/sysroot$SYSTEM" ]]; then
                # TODO overlay is not needed until this point
                ${lib.getExe' config.nix.package.out "nix-store"} --store /tmp/ro-store --load-db < /tmp/ro-store/registration
                # closureInfo doesn't guarantee order for some reason
                ${lib.getExe' config.nix.package.out "nix-store"} --store /tmp/ro-store --query --requisites "$SYSTEM" \
                  | ${lib.getExe' pkgs.findutils "xargs"} ${lib.getExe' config.nix.package.out "nix-store"} --store /tmp/ro-store --export \
                  | ${lib.getExe' config.nix.package.out "nix-store"} --store /sysroot --import
              fi

              umount /tmp/ro-store
              umount /tmp/ro-store-base
              rm -rf /tmp/ro-store*
            '';
          };
        };
      };
    };
  })
]
