# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let smartdnotify = pkgs.writeShellApplication {
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.coreutils ];
    name = "smartdnotify";
    text = ''
#!/bin/bash

set -e

body=$(cat <<-END
{
  "content": $(jq --null-input --arg text "$SMARTD_MESSAGE" '$text'),
  "embeds": [
    {
      "title": "$SMARTD_FAILTYPE",
      "description": $(jq --null-input --arg text "$SMARTD_FULLMESSAGE" '$text'),
      "color": 16711680,
      "fields": [
        {
          "name": "Device",
          "value": "$SMARTD_DEVICE ($SMARTD_DEVICETYPE)"
        },
        {
          "name": "First encounter",
          "value": "<t:$SMARTD_TFIRSTEPOCH:d>"
        },
        {
          "name": "Message number",
          "value": "$((SMARTD_PREVCNT + 1))",
          "inline": true
        },
        {
          "name": "Next message in",
          "value": "$SMARTD_PREVCNT days",
          "inline": true
        }
      ]
    }
  ],
  "username": "Fusion",
  "avatar_url": "https://cdn.discordapp.com/avatars/564403404688850973/5255509ed9be331c5b37aa873c279e6b.png",
  "attachments": []
}
END
)

curl --header "Content-Type: application/json"  --request POST --data "$body" --silent --show-error https://discord.com/api/webhooks/658390924052660246/1nSDsGIsGvyT3EsMKoaWCyAcGyZxQ0T37nNBN29chel-4EtWgWhgpY1c8gfTqRqsNsfV
    '';
  }; in {
  boot.tmp.useTmpfs = true;

  nix = {
    settings = {
      experimental-features = [ "flakes" "nix-command" ];
      auto-optimise-store = true;
    };
  };

  # security.sudo.wheelNeedsPassword = false;

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

      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFVkir1w4CKIl8dTNZ9m7Ecyr1BNJuWdIACol+uFg4BP solidexplorer@lynx"
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
    python3
    gnupg
    rclone
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
      "*/15 * * * * /home/herobrine1st/Docker/grafana/grafanaTask.sh"
    ];
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;
  virtualisation.docker.liveRestore = false;
  virtualisation.docker.storageDriver = "btrfs";

  # Open ports in the firewall.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 4443 8853 ];
    # allowedUDPPorts = [];
  };

  system.stateVersion = "23.11"; # Do not change

}

