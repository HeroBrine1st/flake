{ pkgs, custom-pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    mangohud
    nodejs

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
    freecad
  ];

  nixpkgs.allowedUnfreePackages = [
    "spotify"
    "android-studio-stable"
    "rust-rover"
    "steam" "steam-original" "steam-run"
    "osu-lazer-bin"
    "veracrypt"
    "code" "vscode"
    "winbox"
  ];

  # Place IDE in FHS
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

  programs.adb.enable = true;
  programs.gnupg.agent.enable = true;

  programs.wireshark.enable = true;
  programs.wireshark.package = pkgs.wireshark;

  programs.steam = {
    enable = true;
    package = pkgs.steam.override {
      # fix gamescope on nvidia
      extraBwrapArgs = [ "--ro-bind-try /etc/egl /etc/egl" ];
    };
    #extest.enable = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  boot.blacklistedKernelModules = [ "hid_nintendo" ]; # steam has its own hidraw driver

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;
}