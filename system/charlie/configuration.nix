{ ... }: {
  boot.tmp.useTmpfs = true;

  security.sudo-rs.wheelNeedsPassword = false;

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  zramSwap.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.herobrine1st = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
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

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    liveRestore = false;
    storageDriver = "btrfs";
    daemon.settings = {
      dns = ["1.1.1.1"];
    };
  };

  networking.firewall.allowedTCPPorts = [ 443 42424 ];

  system.stateVersion = "24.11";
}