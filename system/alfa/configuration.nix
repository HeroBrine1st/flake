{ config, lib, pkgs, ... }: {
  boot.tmp.useTmpfs = true;

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  zramSwap.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.herobrine1st = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICs5D9zh4OUHN+wwHiNgiqC4Ec0Qi0qLAyA9oh515HJA herobrine1st@DESKTOP-IJK2GUG"

      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLcsUaFdbPeGO0HPSqsivuaw+/vyCNwChNaQ75d70/y herobrine1st@lynx"
    ];
  };

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICs5D9zh4OUHN+wwHiNgiqC4Ec0Qi0qLAyA9oh515HJA herobrine1st@DESKTOP-IJK2GUG"
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "without-password";
      PasswordAuthentication = false;
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

  networking.firewall.enable = true;

  environment.etc."htoprc".source = ./htoprc;

  system.stateVersion = "23.11"; # Do not change

  # run0 still does not work on nixos 25.05
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = false;
  };
}

