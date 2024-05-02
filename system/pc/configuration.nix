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

  i18n = {
    defaultLocale = "en_GB.UTF-8";
#    supportedLocales = [
#      "en_GB.UTF-8/UTF-8"
#      "ru_RU.UTF-8/UTF-8"
#    ];
  };



  users.users.herobrine1st = {
    isNormalUser = true;
    description = "HeroBrine1st Erquilenne";
    extraGroups = [ "wheel" "docker" "libvirtd" ];
  #  packages = with pkgs; [
  #     firefox
  #     tree
  #  ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhbfIlo673pgcavZFZyKWoMf+Ak0ETfyD1Y89YJJnue solidexplorer@lynx"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMqqnT2Z4o9nZ81w9IbwYC6fkQvPfgGAwhgvBnp1VDWR herobrine1st@lynx"
    ];
  };

  programs.bash.enableCompletion = false;
  programs.bash.promptPluginInit = ''
    # Check whether we're running a version of Bash that has support for
    # programmable completion. If we do, enable all modules installed in
    # the system and user profile in obsolete /etc/bash_completion.d/
    # directories. Bash loads completions in all
    # $XDG_DATA_DIRS/bash-completion/completions/
    # on demand, so they do not need to be sourced here.
    if shopt -q progcomp &>/dev/null; then
      . "${custom-pkgs.bash-completion}/etc/profile.d/bash_completion.sh"
      nullglobStatus=$(shopt -p nullglob)
      shopt -s nullglob
      for p in $NIX_PROFILES; do
        for m in "$p/etc/bash_completion.d/"*; do
          . "$m"
        done
      done
      eval "$nullglobStatus"
      unset nullglobStatus p m
    fi
  '';


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
      evdev
    ]))
    gnupg
    gnumake
    mangohud
    gamescope
    gamemode
    (pkgs.callPackage ../../packages/organize-screenshots.nix {})
    sing-box
    sing-geosite
    sing-geoip
    nodejs
    jetbrains-mono
    dconf2nix
    unzip
    file
    pv

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
    discord custom-pkgs.vesktop
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
    vscode-fhs
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
    (pkgs.wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        obs-vkcapture         
      ];
    })

    # "Security"
    veracrypt
    keepassxc
    gnome.seahorse
    # windscribe unavailable

    # Other desktop applications
    ungoogled-chromium
    gnome.dconf-editor
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
    enable = true;
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
    allowedTCPPorts = [ 22 8384 22000 ];
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

  environment.sessionVariables = rec {
    NAUTILUS_4_EXTENSION_DIR = "/run/current-system/sw/lib/nautilus/extensions-4/";
  };

  system.stateVersion = "23.11"; # Do not change
}

