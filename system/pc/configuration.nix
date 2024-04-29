# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, fetchUrl, custom-pkgs, ... }: {
  imports = [
    ../../shared/firejail.nix
  ];

  boot.tmp.useTmpfs = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "discord"
    "nvidia-x11" "nvidia-settings"
    "spotify"
    "android-studio-stable"
    "idea-ultimate"
    "pycharm-professional"
    "webstorm"
    "clion"
    "rust-rover"
    "steam" "steam-original"
    "osu-lazer-bin"
    "veracrypt"
    "code" "vscode"
    "winbox"
  ];

  nix = {
    settings = {
      experimental-features = [ "flakes" "nix-command" ];
      auto-optimise-store = true;
    };
  };

  # security.sudo.wheelNeedsPassword = false;

  networking.hostName = "DESKTOP-IJK2GUG";
  networking.networkmanager.enable = true;

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

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.herobrine1st = {
    isNormalUser = true;
    description = "HeroBrine1st Erquilenne";
    extraGroups = [ "wheel" "docker" "libvirtd" ];
  #  packages = with pkgs; [
  #     firefox
  #     tree
  #  ];
    openssh.authorizedKeys.keys = [
      # TODO
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
    (python3.withPackages(pythonPkgs: with pythonPkgs; [
      rich
      ptpython
    ]))
    gnupg
    gnumake
    mangohud
    gamescope
    gamemode
    obs-studio-plugins.obs-vkcapture
    (pkgs.callPackage ../../packages/organize-screenshots.nix {})
    sing-box
    sing-geosite
    sing-geoip
    nodejs
    jetbrains-mono
    dconf2nix
    unzip
    file

    gnome.gnome-themes-extra # Adwaita-dark

    # Extensions
    gnomeExtensions.control-blur-effect-on-lock-screen
    gnomeExtensions.panel-corners # outdated, available on EGO
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
    gnome.gnome-terminal
    gnome.nautilus
    firefox-bin
    discord
    element-desktop
    custom-pkgs.spotify

    # "Personal"
    gnome.gnome-weather
    gnome.gnome-calendar
    gnome.gnome-clocks
    gnome.gnome-maps
    xournalpp
    krita

    # "System maintenance"
    gnome.gnome-control-center
    # timeshift pointless
    gnome.gnome-system-monitor
    # opentabletdriver inferred
    # gnome-extensions inferred from gnome-shell
    pavucontrol
    # grub-customizer not needed
    gnome.gnome-tweaks
    # nvidia x server settings inferred
    gnome.gnome-logs
    helvum
    easyeffects

    # "Media"
    gthumb
    vlc
    gnome.totem
    picard
    mpv
    handbrake

    # "Utilities"
    gnome.gnome-disk-utility
    gnome.gnome-calculator
    baobab # Disk Usage Analyzer
    gnome.file-roller
    gparted
    evince # GNOME Document Viewer
    gnome-text-editor
    virt-manager
    lshw
    gnome.gnome-nettool


    # "Development"
    android-studio android-tools
    (jetbrains.idea-ultimate.overrideAttrs {
      version = "2022.3.3";
      src = fetchurl {
        url = "https://download.jetbrains.com/idea/ideaIU-2022.3.3.tar.gz";
        sha256 = "c302bd84b48a56ef1b0f033e8e93a0da5590f80482eae172db6130da035314a6";
      };
    })
    custom-pkgs.pycharm-professional
# does not build
#    (jetbrains.pycharm-professional.overrideAttrs {
#      version = "2022.3.3";
#      src = fetchurl {
#        url = "https://download.jetbrains.com/python/pycharm-professional-2022.3.3.tar.gz";
#        sha256 = "50c37aafd9fbe3a78d97cccf4f7abd80266c548d1c7ea4751b08c52810f16f2d";
#      };
#    })
    (jetbrains.webstorm.overrideAttrs {
      version = "2022.3.4";
      src = fetchurl {
        url = "https://download.jetbrains.com/webstorm/WebStorm-2022.3.4.tar.gz";
        sha256 = "c33f72b5e26f347983b7bae92608d9b4343dcbb400736addb0793407aedc3260";
      };
    })
    (jetbrains.clion.overrideAttrs {
      version = "2022.3.3";
      src = fetchurl {
        url = "https://download.jetbrains.com/cpp/CLion-2022.3.3.tar.gz";
        sha256 = "1b46ff0791bcb38ecb39c5f4a99941f99ed73d4f6d924a2042fdb55afc5fc03d";
      };
    })
    gcc cmake
    arduino
    jetbrains.rust-rover
    jetbrains.idea-community
    # fleet unavailable


    # "Office"
    libreoffice-fresh

    # "Games"
    steam
    osu-lazer-bin
    lutris
    # TLauncher unavailable
    # CKAN not needed yet
    # protontricks not needed yet
    obs-studio

    # "Security"
    veracrypt
    keepassxc
    gnome.seahorse
    # windscribe unavailable

    # Other desktop applications
    ungoogled-chromium
    gnome.dconf-editor
    vscode-fhs
    winbox
    ventoy
    gnome-connections # RDP client
    feishin
    bytecode-viewer

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

  programs.nano.nanorc = ''
    set tabsize 4
    set tabstospaces
  '';

  services.openssh = {
    enable = false;
    settings = {
      PermitRootLogin = "without-password";
      PasswordAuthentication = false;
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
    allowedTCPPorts = [ 8384 22000 ];
    allowedUDPPorts = [ 22000 21027 ];
    allowedTCPPortRanges = [
      { from = 1714; to = 1764; } # KDE Connect
    ];
    allowedUDPPortRanges = [
      { from = 1714; to = 1764; } # KDE Connect
    ];
  };

  services.syncthing = {
    enable = true;
    user = "herobrine1st";
    configDir = "/home/herobrine1st/.config/Syncthing";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        "OPi5" = {
          id = "QDEHB5B-UGM2GQ6-3VG3RBL-JXOTGB2-OGNO5AL-H7KAFIC-MESTOWJ-O2YD3AO";
        };
        "MOBILE-DCV5AQD" = {
          id = "NUNTZPB-Z4CHNKA-3B3NF3Y-CREPZRK-P753FR3-WLMECWN-LGUDDN2-SB2ECQF";
        };
      };
      folders = {
        "uf77h-ptigu" = {
          label = "Secure";
          path = "/mnt/secure";
          devices = [ "OPi5" "MOBILE-DCV5AQD" ];
        };
        "yb6rg-qs9gm" = {
          label = "Local Music";
          path = "/home/herobrine1st/Music/Main";
          devices = [ "OPi5" "MOBILE-DCV5AQD" ];
        };
      };
    };
  };


  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      "idea-community" = {
        executable = "${pkgs.jetbrains.idea-community}/bin/idea-community";
        extraArgs = [
          "--noprofile"
          "--env=LD_LIBRARY_PATH=${pkgs.libGL}/lib"
        ];
      };
    };
  };

  system.stateVersion = "23.11"; # Do not change
}

