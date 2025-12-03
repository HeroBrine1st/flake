{ ... }: {
  boot.tmp.useTmpfs = true;

  security.sudo-rs.wheelNeedsPassword = false;

  time.timeZone = "Europe/Moscow";

  zramSwap.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.herobrine1st = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
  };

  services.openssh = {
    enable = true;
    restrictToOverlay = true;
    settings = {
      PermitRootLogin = "without-password";
      PasswordAuthentication = false;
    };
  };

  services.cron.enable = true;

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    liveRestore = false;
    storageDriver = "overlay2";
    daemon.settings = {
      dns = ["1.1.1.1"];
    };
  };

  networking.firewall.allowedTCPPorts = [ 443 42424 ];

  system.stateVersion = "24.11";

  # run0 still does not work on nixos 25.05
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
  };

  nix.useFlakeCache = false;
}