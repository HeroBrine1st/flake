{ pkgs, ... }: {
  boot.tmp.useTmpfs = true;

  security.sudo-rs.wheelNeedsPassword = false;

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  zramSwap.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.herobrine1st = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyZILdbeUexMmf6aJcKnP8Rbv2hkDqv9xeGOnNjs20G herobrine1st@DESKTOP-IJK2GUG"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID0zqkL/3T1RkNOV2F8QSR+yy6GPcNeufSWJi6FFsLs4 herobrine1st@MOBILE-DCV5AQD"
    ];
  };

  environment.systemPackages = with pkgs; [
    ctop
    rclone
  ];

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

  environment.etc."htoprc".source = ./htoprc;

  system.stateVersion = "24.11";

   # run0 still does not work on nixos 25.05
   security.sudo-rs = {
     enable = true;
     execWheelOnly = true;
   };
}