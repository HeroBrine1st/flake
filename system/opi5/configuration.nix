{ config, lib, pkgs, ... }: {
  boot.tmp.useTmpfs = true;

  nix = {
    settings = {
      experimental-features = [ "flakes" "nix-command" ];
      auto-optimise-store = true;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  zramSwap.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.herobrine1st = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICs5D9zh4OUHN+wwHiNgiqC4Ec0Qi0qLAyA9oh515HJA herobrine1st@DESKTOP-IJK2GUG"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvg7OeMT5A85IBk9G4Y7utsVVw/B5L4J3F7BPizwFET herobrine1st@MOBILE-DCV5AQD"

      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLcsUaFdbPeGO0HPSqsivuaw+/vyCNwChNaQ75d70/y herobrine1st@lynx"
    ];
  };

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICs5D9zh4OUHN+wwHiNgiqC4Ec0Qi0qLAyA9oh515HJA herobrine1st@DESKTOP-IJK2GUG"
    ];
  };

  environment.systemPackages = with pkgs; [
    duplicity
    ctop
    rclone
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "without-password";
      PasswordAuthentication = false;
      Macs = [
        "hmac-sha2-512"
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
      ];
    };
  };
  services.udisks2.enable = true;

  services.cron.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;
  virtualisation.docker.liveRestore = false;
  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.docker.daemon.settings = {
    dns = [ "1.1.1.1" ];
  };

  networking.firewall = {
    trustedInterfaces = [
      "sing-box-tun"
    ];
    enable = true;

    # Syncthing
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [ 22000 21027 ];
  };

  environment.etc."htoprc".source = ./htoprc;

  system.stateVersion = "23.11"; # Do not change
}

