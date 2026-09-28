{ flake, pkgs, config, lib, ... }: let
  wrappedPackage = pkgs.buildFHSEnv {
    name = "letta-code-wrapped";
    targetPkgs = pkgs: with pkgs; [
      nodejs
      bubblewrap
    ];
    executableName = "letta";
    runScript = "${flake.pkgs.letta-code}/bin/letta";
  };
in {
  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=25%" "mode=755" ];
    };
  };

  # letta-code is installed but not yet enabled as a systemd service;
  # to enable later: services.letta-code.enable = true
  # (see the letta-code flake's nixosModules.letta-code for the rest of the options)
  # the package in flake.pkgs overrides the stale bunDeps (see packages/letta-code/default.nix)
  environment.systemPackages = with pkgs; [
    wrappedPackage
  ];

  services.letta-code = {
    enable = true;
    package = wrappedPackage;
    extraArgs = [
      "server"
      "--channels" "telegram"
      "--install-channel-runtimes"
    ];
  };

  users.users.letta-code = {
    isSystemUser = lib.mkForce false;
    isNormalUser = true;
  };

  services.impermanence = {
    enable = true;
    extraDirectories = [
      "/home"
      { directory = config.services.letta-code.workingDirectory; user = "letta-code"; group = "letta-code"; mode = "0700"; }
    ];
  };

  # /var/lib/letta-code must be a btrfs subvolume on the /nix volume
  # (i.e. /nix/persist/system/var/lib/letta-code), so that it can be snapshotted
  # with the rest of the persistent data. Impermanence's createPersistentStorageDirs
  # would otherwise mkdir it as a plain directory, so create the subvolume first.
  system.activationScripts.create-letta-code-subvolume = {
    text = ''
      set -euo pipefail
      dir=/nix/persist/system/var/lib/letta-code
      if [[ ! -d $dir ]]; then
        mkdir -p /nix/persist/system/var/lib
        ${pkgs.btrfs-progs}/bin/btrfs subvolume create $dir
      else
        # warn if an older guest version created it as a plain directory
        ! ${pkgs.btrfs-progs}/bin/btrfs subvolume list -s -o /nix/persist/system | grep -qx "var/lib/letta-code" \
          && echo "WARNING: $dir exists but is not a btrfs subvolume" >&2
      fi
    '';
  };
  system.activationScripts."createPersistentStorageDirs".deps = [ "create-letta-code-subvolume" ];

  security.sudo-rs = {
    enable = true;
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  users.users.herobrine1st = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMx6iwADwNH6wLURS6/jfa7mlKB9wXAPJaN8x61JainS herobrine1st@foxtrot"
    ];
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      AllowUsers = [ "herobrine1st" ];
    };
  };
}
