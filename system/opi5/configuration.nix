# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:
let
  smartdnotify = pkgs.callPackage ../../packages/smartdnotify.nix {};
in
{
  boot.tmp.useTmpfs = true;

  nix = {
    settings = {
      experimental-features = [ "flakes" "nix-command" ];
      auto-optimise-store = true;
    };
  };

   security.sudo.wheelNeedsPassword = false;

  networking.hostName = "opi5";
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  zramSwap.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.herobrine1st = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
  #  packages = with pkgs; [
  #     firefox
  #     tree
  #  ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICs5D9zh4OUHN+wwHiNgiqC4Ec0Qi0qLAyA9oh515HJA herobrine1st@DESKTOP-IJK2GUG"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMvg7OeMT5A85IBk9G4Y7utsVVw/B5L4J3F7BPizwFET herobrine1st@MOBILE-DCV5AQD"

      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIANeHsIs+Zvz0YQn0Vfwzb7OKYy4+4FANzdCbjYZ3s6U herobrine1st@ZB602KL"
      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIIU05hdK6vf9zmC4od6Qbja5HeNM8NSmqX+0sQFjjmI solidexplorer@ZB602KL"

      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILXHFHXgJNzzhhP22ANBqoNUKHhqwSvmRXs2Sz1DETwK herobrine1st@lynx"
    ];
  };

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICs5D9zh4OUHN+wwHiNgiqC4Ec0Qi0qLAyA9oh515HJA herobrine1st@DESKTOP-IJK2GUG"
    ];
  };

  environment.systemPackages = with pkgs; [
    nano
    wget
    curl
    hdparm
    smartmontools
    docker-compose
    htop
    udisks
    tree
    ffmpeg
    yt-dlp
    usbutils
    git
    tcpdump
    lm_sensors
    psmisc
    duplicity
    ctop
    smartdnotify
    (python3.withPackages(pythonPkgs: with pythonPkgs; [
      rich
    ]))
    gnupg
    rclone
    gnumake
    unzip
    file
    pv
    sing-box
    sing-geosite
    sing-geoip
  ];

  programs.nano.nanorc = ''
    set tabsize 4
    set tabstospaces
  '';

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
# doesn't work
#    extraConfig = ''
#      Match Address 192.168.0.0/16
#        PasswordAuthentication yes
#    '';
  };
  services.udisks2.enable = true;

  services.smartd = {
    enable = true;
    devices = [
      {
        device = "/dev/disk/by-id/ata-ST1000LM035-1RK172_WQ9C5SMW";
        options = "-H -p -f -t -l error -l selftest -l selfteststs -C 197 -U 198 -m noemail@example.com -M test -M exec ${smartdnotify}/bin/smartdnotify";
      }
      {
        device = "/dev/nvme0";
        options = "-d nvme -H -l error -W 5,60,80 -m noemail@example.com -M test -M exec ${smartdnotify}/bin/smartdnotify";
      }
    ];
    notifications.test = true;
    notifications.wall.enable = false;
  };

  services.cron = {
    enable = true;
    systemCronJobs = [
      "*/15 * * * * root . /etc/profile; /home/herobrine1st/Docker/grafana/grafanaTask.sh 2>&1 > /root/grafanaTask.log"
    ];
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;
  virtualisation.docker.liveRestore = false;
  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.docker.daemon.settings = {
    dns = [ "1.1.1.1" ];
  };

  # Open ports in the firewall.
  networking.firewall = {
    trustedInterfaces = [
      "sing-box-tun"
    ];
    enable = true;
    # allowedTCPPorts = [];
    # allowedUDPPorts = [];
  };

  system.stateVersion = "23.11"; # Do not change

}

