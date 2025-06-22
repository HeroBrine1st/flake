# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, fetchUrl, custom-pkgs, ... }: {
  imports = [
    ./firejail
    ./gnome
    # ./hyprland # WIP
    ./programs.nix
    ./users.nix
    ./ollama.nix
  ];

  boot.tmp.useTmpfs = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  nix = {
    settings = {
      experimental-features = [ "flakes" "nix-command" ];
      auto-optimise-store = true;
    };
  };

  # security.sudo.wheelNeedsPassword = false;

  services.displayManager.gdm.enable = true;
  documentation.nixos.enable = false;

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  zramSwap.enable = true;

  i18n = {
    defaultLocale = "en_GB.UTF-8";
    supportedLocales = [
      "en_GB.UTF-8/UTF-8"
      "ru_RU.UTF-8/UTF-8"
    ];
  };

  environment.systemPackages = with pkgs; [
    jetbrains-mono

    gnome-themes-extra # Adwaita-dark

    oreo-cursors-plus
    custom-pkgs.arc-x-icon-theme
  ];

  virtualisation.libvirtd = {
    enable = true;
    package = pkgs.libvirt.override {
      # Is not substituted (allowing me to spot that) and is not needed.
      # 4 minute build compared to 7 minute kernel build both on my best build machine is too much
      enableXen = false;
    };
    qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };
  services.pulseaudio.enable = false;

  hardware.opentabletdriver.enable = true;

  services.openssh = {
    # Enabled per-machine
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      Macs = [
        "hmac-sha2-512" # support some legacy clients
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
      ];
    };
  };

  services.udisks2.enable = true;

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    liveRestore = false;
    storageDriver = "btrfs";
    daemon.settings.dns = [ "1.1.1.1" ];
  };

  # Open ports in the firewall.
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "sing-box-tun" ];
  };

  system.stateVersion = "23.11"; # Do not change
}

