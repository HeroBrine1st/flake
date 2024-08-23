# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, fetchUrl, custom-pkgs, ... }: {
  boot.tmp.useTmpfs = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.blacklistedKernelModules = [ "hid_nintendo" ];

  nix = {
    settings = {
      experimental-features = [ "flakes" "nix-command" ];
      auto-optimise-store = true;
    };
  };

  # security.sudo.wheelNeedsPassword = false;

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.gnome.core-utilities.enable = false;
  environment.gnome.excludePackages = [ pkgs.gnome-tour ];
  services.xserver.excludePackages = [ pkgs.xterm ];
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
    mangohud
    nodejs
    jetbrains-mono

    gnome-themes-extra # Adwaita-dark

    # Extensions
    gnomeExtensions.control-blur-effect-on-lock-screen
    gnomeExtensions.panel-corners
    gnomeExtensions.primary-input-on-lockscreen
    gnomeExtensions.quick-settings-tweaker
    # gnomeExtensions.removable-drive-menu # somehow already available
    gnomeExtensions.spotify-tray
    gnomeExtensions.system-monitor-next
    gnomeExtensions.dash-to-dock
    gnomeExtensions.unite xorg.xprop
    gnomeExtensions.gsconnect
    gnomeExtensions.clipboard-indicator

    oreo-cursors-plus
    (callPackage ../../packages/arc-x-icons.nix {})

    # Dash
    gnome-terminal
    nautilus
    firefox-bin
    custom-pkgs.vesktop
    element-desktop
    custom-pkgs.spotify

    # "Personal"
    gnome.gnome-weather
    gnome-calendar
    gnome.gnome-clocks
    gnome.gnome-maps
    xournalpp
    krita

    # "System maintenance"
    gnome.gnome-control-center
    # timeshift pointless
    gnome-system-monitor
    # opentabletdriver inferred
    # gnome-extensions inferred from gnome-shell
    pavucontrol
    # grub-customizer not needed
    gnome-tweaks
    # nvidia x server settings inferred
    gnome.gnome-logs
    helvum
    # easyeffects can't pass tests

    # "Media"
    gthumb
    vlc
    totem # gnome
    picard
    mpv
    handbrake

    # "Utilities"
    gnome-disk-utility
    gnome-calculator
    baobab # Disk Usage Analyzer
    file-roller
    gparted
    evince # GNOME Document Viewer
    gnome-text-editor
    virt-manager
    lshw
    # wireshark inferred
    gnome.gnome-nettool


    # "Development"
    android-studio
    custom-pkgs.jetbrains.idea-ultimate
    #custom-pkgs.jetbrains.pycharm-professional
    jetbrains.pycharm-community-bin
    custom-pkgs.jetbrains.webstorm
    custom-pkgs.jetbrains.clion
    gcc cmake
    arduino-ide
    jetbrains.rust-rover
    jetbrains.idea-community-bin
    (vscode-with-extensions.override {
      vscode = vscodium.fhsWithPackages (ps: [ ps.nixd ]);
      vscodeExtensions = with vscode-extensions; [
        jnoortheen.nix-ide
        k--kato.intellij-idea-keybindings
      ];
    })
    # fleet unavailable

    # "Office"
    libreoffice-fresh

    # "Games"
    # steam inferred by programs.steam.enable = true
    osu-lazer-bin
    lutris
    custom-pkgs.tlauncher
    # CKAN not needed yet
    # protontricks not needed yet
    (pkgs.wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        obs-vkcapture         
      ];
    })

    # "Security"
    veracrypt
    keepassxc
    seahorse # gnome
    # windscribe unavailable

    # Other desktop applications
    ungoogled-chromium
    dconf-editor
    winbox
    ventoy
    gnome-connections # RDP client
    feishin
    bytecode-viewer
    audacity
    lrcget
    finamp
    bottles
  ];

  virtualisation.libvirtd.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  hardware.opentabletdriver.enable = true;
  hardware.pulseaudio.enable = false;

  services.openssh = {
    # Enabled per-machine
    settings = {
      PermitRootLogin = "no";
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

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = false;
  virtualisation.docker.liveRestore = false;
  virtualisation.docker.storageDriver = "btrfs";
  virtualisation.docker.daemon.settings = {
    dns = [ "1.1.1.1" ];
  };

  # Open ports in the firewall.
  networking.firewall = {
    enable = true;
    trustedInterfaces = [
      "sing-box-tun"
    ];
    allowedTCPPorts = [ 
      22000 # syncthing
      8080 # idk
      57621 # spotify connect
    ];
    allowedUDPPorts = [ 
      22000 21027 # syncthing
    ];
    allowedTCPPortRanges = [
      { from = 1714; to = 1764; } # KDE Connect
    ];
    allowedUDPPortRanges = [
      { from = 1714; to = 1764; } # KDE Connect
    ];
  };



  programs.wrappedBinaries = {
    enable = true;
    binaries = {
      "idea-community" = {
        cmdline = [
          "${pkgs.callPackage ../../packages/android-fhs-env.nix {}}/bin/android-fhs-env"
          "LD_LIBRARY_PATH=${pkgs.libGL}/lib"
          "${pkgs.jetbrains.idea-community-bin}/bin/idea-community"
        ];
      };
      "pycharm-community" = {
        cmdline = [
          "${pkgs.callPackage ../../packages/pycharm-fhs-env.nix {}}/bin/pycharm-fhs-env"
          "${pkgs.jetbrains.pycharm-community-bin}/bin/pycharm-community"
        ];
      };
    };
  };

  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark;

  programs.adb.enable = true;

  programs.gnupg.agent.enable = true;
  programs.steam = {
    enable = true;
    package = pkgs.steam.override {
      extraBwrapArgs = [ "--ro-bind-try /etc/egl /etc/egl" ];
    };
    #extest.enable = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  environment.sessionVariables = rec {
    NAUTILUS_4_EXTENSION_DIR = "/run/current-system/sw/lib/nautilus/extensions-4/";
  };

  system.stateVersion = "23.11"; # Do not change
}

