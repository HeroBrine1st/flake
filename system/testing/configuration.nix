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
        # apply full patch not restricted by sourceRoot, as it is a complete patch ready for upstreaming
        # the patch is taken from https://github.com/kata-containers/kata-containers/pull/7648 and updated to resolve conflicts
        # I know about -p3 and --directory, no both won't work (in latter case /build/source/tests is read-only)
        src = pkgs.stdenv.mkDerivation rec {
          src = pkgs.fetchFromGitHub {
            owner = "kata-containers";
            repo = "kata-containers";
            rev = "758471cbddeff44297ca5a3db9340bad0c3360ef"; # pull/11749/head
            hash = "sha256-tH395Uz1vdm/9rvFVKcfycMEuSDfWJ9S798n0wb7EBg=";
          };
          name = src.name;

          phases = [ "unpackPhase" "patchPhase" "installPhase" ];
          installPhase = "cp --archive . $out";
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