{ host, nix-store-disk, machine }: { lib, utils, ... }@guest: {
  networking.hostName = lib.mkDefault machine.name;
  nixpkgs = { inherit (host.pkgs.stdenv) hostPlatform; };
  system = lib.mkDefault { inherit (host.config.system) stateVersion; };
  boot.kernelParams = [ "console=hvc0" ];


  boot.initrd.systemd = {
    enable = true;
    services.tidy-nix-store = rec {
      requiredBy = [
        "${utils.escapeSystemdPath "/sysroot/nix/store"}.mount"
      ];
      # Assuming /nix/.rw-store is mounted as /nix, which is dependency of /nix/.ro-store
      requires = [
        "${utils.escapeSystemdPath "/sysroot/nix/.ro-store"}.mount"
      ];

      after = requires;
      before = requiredBy;

#      unitConfig = {
#        # is it needed?
#        RequiresMountsFor = [
#          "/sysroot/nix/.ro-store"
#          "/sysroot/nix/.rw-store"
#        ];
#      };

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/bin/bash -c 'cd /nix/.rw-store && rm -rf $(ls /nix/.ro-store)'";
      };
    };
  };

  # https://github.com/NixOS/nixpkgs/blob/fd255281e2c710f08ced79312bac0b88c8c2f8ba/nixos/modules/installer/cd-dvd/iso-image.nix
  # it's possible that it's not good idea because store paths can be removed afterwards
  # a better idea is to copy store paths to guest in stage 1
  # then register in stage 2
  systemd.services.register-nix-paths = {
    description = "Register Nix Store Paths";
    unitConfig.DefaultDependencies = false;
    wantedBy = [ "sysinit.target" ];
    before = [
      "sysinit.target"
      "shutdown.target"
      "nix-daemon.socket"
      "nix-daemon.service"
    ];
    after = [ "local-fs.target" ];
    conflicts = [ "shutdown.target" ];
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # After booting, register the contents of the Nix store on the
      # CD in the Nix database in the tmpfs.
      ${lib.getExe' guest.config.nix.package.out "nix-store"} --load-db < /nix/store/registration

      # not supported
      # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
      #touch /etc/NIXOS
      #${lib.getExe' guest.config.nix.package.out "nix-env"} -p /nix/var/nix/profiles/system --set /run/current-system
    '';
  };

  fileSystems = {
    "/nix/.ro-store" = {
      device = "/dev/${nix-store-disk}";
      fsType = "erofs";
      options = [ "defaults" "ro" ];
      neededForBoot = true;
    };
    "/nix/store" = {
      overlay = {
        lowerdir = [ "/nix/.ro-store" ];
        upperdir = "/nix/.rw-store";
        workdir = "/nix/.wd-store";
      };
      neededForBoot = true;
    };
  };

  nix = {
    channel.enable = false;
    nixPath = [
      "nixpkgs=flake:nixpkgs"
    ];
  };
}