{ pkgs, custom-pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    mangohud
    nodejs

    # Dash
    gnome-terminal
    nautilus
    # firefox-bin inferred from programs.firefox.enable
    element-desktop
    custom-pkgs.spotify

    # "Personal"
    gnome-weather
    gnome-calendar
    gnome-clocks
    gnome-maps
    xournalpp
    krita

    # "System maintenance"
    gnome-control-center
    # timeshift pointless
    gnome-system-monitor
    # opentabletdriver inferred
    # gnome-extensions inferred from gnome-shell
    pavucontrol
    # grub-customizer not needed
    gnome-tweaks
    # nvidia x server settings inferred
    gnome-logs
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
    gnome-nettool


    # "Development"
    android-studio
    custom-pkgs.jetbrains.idea-ultimate
    #custom-pkgs.jetbrains.pycharm-professional
    jetbrains.pycharm-community-bin
    jetbrains.webstorm
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
    (feishin.override { electron_31 = electron_33; })
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
    "webstorm"
    "steam" "steam-original" "steam-run" "steam-unwrapped"
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
          "${pkgs.callPackage ../../packages/idea-fhs-env.nix {}}/bin/idea-fhs-env"
          "LD_LIBRARY_PATH=${pkgs.libGL}/lib"
          "${pkgs.jetbrains.idea-community-bin}/bin/idea-community"
        ];
      };
      "pycharm-community" = {
        cmdline = [
          "${pkgs.callPackage ../../packages/pycharm-fhs-env.nix {}}/bin/pycharm-fhs-env"
          "PIPENV_VENV_IN_PROJECT=1"
          # "PIPENV_CUSTOM_VENV_NAME=venv" does not work with venv in project
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

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-bin;
    autoConfig = ''
      lockPref("cookiebanners.service.mode", 1);
      lockPref("cookiebanners.service.mode.privateBrowsing", 1);
      lockPref("network.trr.allow-rfc1918", true);
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [
      57621 # spotify connect
    ];
  };
}
