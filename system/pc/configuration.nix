# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, fetchUrl, ... }: {
  boot.tmp.useTmpfs = true;

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

  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gedit
  ]) ++ (with pkgs.gnome; [
    cheese # webcam tool
    gnome-music
    epiphany # web browser
    geary # email reader
    evince # document viewer
    gnome-characters
    totem # video player
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
  ]);

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
    (pkgs.callPackage ../../packages/organize-screenshots.nix {})
    sing-box
    sing-geosite
    sing-geoip
    nodejs


    # Extensions
    gnomeExtensions.control-blur-effect-on-lock-screen
    # gnomeExtensions.panel-corners outdated, available on EGO
    gnomeExtensions.primary-input-on-lockscreen
    gnomeExtensions.quick-settings-tweaker
    # gnomeExtensions.removable-drive-menu outdated, available on EGO
    gnomeExtensions.spotify-tray
    gnomeExtensions.system-monitor-next
    gnomeExtensions.dash-to-dock
    gnomeExtensions.unite xorg.xprop
    gnomeExtensions.gsconnect

    oreo-cursors-plus

    # Dash
    gnome.gnome-terminal
    gnome.nautilus
    firefox-bin
    discord
    element-desktop
    spotify

    # "Personal"
    gnome.gnome-weather
    gnome.gnome-calendar
    gnome.gnome-clocks
    gnome.gnome-maps
    xournalpp
    krita

    # "System maintenance"
    # gnome-settings inferred
    # timeshift pointless
    gnome.gnome-system-monitor
    # opentabletdriver inferred
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
    gnome.gnome-boxes
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
    #winbox
    ventoy
    gnome-connections # RDP client
    feishin
    bytecode-viewer

  ];

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
    # allowedTCPPorts = [];
    # allowedUDPPorts = [];
  };

  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      lutris = {
        executable = "${pkgs.lutris}/bin/lutris";
        profile = "${pkgs.firejail}/etc/firejail/lutris.profile";
        extraArgs = [
          "--ignore=mkdir \${HOME}/Games"
          "--ignore=whitelist \${HOME}/Games"
          "--ignore=whitelist \${DOWNLOADS}"
          "--blacklist=\${DOWNLOADS}"

          "--noblacklist=\${HOME}/.config/MangoHud"
          "--whitelist=\${HOME}/.config/MangoHud"
          "--whitelist=/mnt/extra/Lutris"
          "--whitelist=\${HOME}/.cache/lutris"
          "--whitelist=\${HOME}/.cache/wine"
          "--whitelist=\${HOME}/.cache/winetricks"

          "--ignore=seccomp !modify_ldt"
          "--ignore=ignore seccomp.32 !modify_ldt"

          "--apparmor"

          "--deterministic-shutdown"

          "--join-or-start=lutris"
        ];
      };
      node = {
        executable = "${pkgs.nodejs}/bin/node";
        profile = "${pkgs.firejail}/etc/firejail/node.profile";
        extraArgs = [
          "--mkdir=~/.node-gyp"
          "--mkdir=~/.npm"
          "--mkdir=~/.npm-packages"
          "--mkfile=~/.npmrc"
          "--mkdir=~/.nvm"
          "--mkdir=~/.yarn"
          "--mkdir=\${HOME}/.yarn-config"
          "--mkdir=\${HOME}/.yarncache"
          "--mkfile=\${HOME}/.yarnrc"
          "--whitelist=\${HOME}/.node-gyp"
          "--whitelist=\${HOME}/.npm"
          "--whitelist=\${HOME}/.npm-packages"
          "--whitelist=\${HOME}/.npmrc"
          "--whitelist=\${HOME}/.nvm"
          "--whitelist=\${HOME}/.yarn"
          "--whitelist=\${HOME}/.yarn-config"
          "--whitelist=\${HOME}/.yarncache"
          "--whitelist=\${HOME}/.yarnrc"
          "--whitelist=\${HOME}/Git"
          "--include=whitelist-common.inc"
        ];
      };
      spotify = {
        executable = "${pkgs.spotify}/bin/spotify";
        profile = "${pkgs.firejail}/etc/firejail/spotify.profile";
        extraArgs = [
          "--join-or-start=spotify"
          "--whitelist=\${HOME}/Music/Main"
        ];
      };
      steam = {
        executable = "${pkgs.steam}/bin/steam";
        profile = "${pkgs.firejail}/etc/firejail/steam.profile";
        extraArgs = [
          "--ignore=private-etc"
          "--ignore=restrict-namespaces"
          "--ignore=seccomp"

          # Gamepad
          "--ignore=private-dev"
          "--ignore=nou2f"
          "--ignore=noroot"

          # gamescope
          #"--ignore=private-tmp"

          # Generic configuration
          "--noblacklist=\${HOME}/.cache"
          "--noblacklist=/mnt/games/Steam"
          "--noblacklist=/mnt/games_hdd/Steam"
          "--noblacklist=/mnt/games_ssd/Steam"
          "--whitelist=\${HOME}/.cache"
          "--whitelist=/mnt/games/Steam"
          "--whitelist=/mnt/extra/Steam"
          "--caps.keep=sys_nice"
          "--join-or-start=steam"

          # Factorio
          "--noblacklist=\${HOME}/.factorio"
          "--whitelist=\${HOME}/.factorio"

          # Elite: Dangerous
          "--env=DOTNET_BUNDLE_EXTRACT_BASE_DIR=/mnt/extra/Steam/.dotnet_bundle_extract"
          "--whitelist=\${HOME}/.config/min-ed-launcher"
        ];
      };
      #steam-runtime
      discord = {
        executable = "${pkgs.discord}/opt/Discord/Discord";
        profile = "${pkgs.firejail}/etc/firejail/discord.profile";
        extraArgs = [
          "--ignore=whitelist \${DOWNLOADS}"
          "--whitelist=/mnt/tmp"
          "--blacklist=/dev/snd"
        ];
      };
      Discord = {
        executable = "${pkgs.discord}/opt/Discord/Discord";
        profile = "${pkgs.firejail}/etc/firejail/discord.profile";
        extraArgs = [
          "--ignore=whitelist \${DOWNLOADS}"
          "--whitelist=/mnt/tmp"
          "--blacklist=/dev/snd"
        ];
      };
    };
  };


  system.stateVersion = "23.11"; # Do not change
}

