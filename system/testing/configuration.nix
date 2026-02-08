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
    extraPackages = [
      (pkgs.kata-runtime.overrideAttrs(old: {
        hardeningDisable = [];
        src = pkgs.fetchFromGitHub {
          owner = "kata-containers";
          repo = "kata-containers";
          rev = "4fe59cf0992375d6aca44dfe05f9192f98de5a50"; # pull/11749/head
          hash = "sha256-tWHiNiebQgTEAkFx8Kt+ABlyJNnxK5r4/prvEeTW8JU=";
        };
      }))
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
    };
  };

  system.stateVersion = "25.05";

  # run0 still does not work on nixos 25.05
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
  };
}