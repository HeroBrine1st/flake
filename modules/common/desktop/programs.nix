{ pkgs, custom-pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    mangohud
    nodejs

    # Dash
    gnome-terminal
    nautilus
    # firefox-bin inferred from programs.firefox.enable
    element-desktop
    feishin

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
        ms-python.python
        ms-toolsai.jupyter
        continue.continue
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
    gnome-connections # RDP client
    bytecode-viewer
    audacity
    lrcget
    finamp
    freecad

    # CLI
    typst
  ];

  nixpkgs.allowedUnfreePackages = [
    "android-studio-stable"
    "rust-rover"
    "webstorm"
    "steam" "steam-original" "steam-run" "steam-unwrapped"
    "osu-lazer-bin"
    "veracrypt"
    "code" "vscode"
    "winbox"
  ];

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
  programs.gamescope = {
    enable = true;
    package = pkgs.gamescope.overrideAttrs(old: {
      patches = (old.patches or []) ++ [
        (pkgs.fetchpatch {
          url = "https://github.com/ValveSoftware/gamescope/pull/1867.patch";
          hash = "sha256-ONjSInJ7M8niL5xWaNk5Z16ZMcM/A7M7bHTrgCFjrts=";
        })
      ];
    });
    # `gamescope.convars.drm_debug_disable_explicit_sync.value = true` in ~/.config/gamescope/scripts/es.lua
    # may help with out of order frame presentation (yes, explicit sync triggers OOFP while was created to fix that! and
    # somehow it works on wayland backend despite being defined in DRM backend)
    # Beware this adds one more frame delay
  };

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    autoConfig = ''
      lockPref("cookiebanners.service.mode", 1);
      lockPref("cookiebanners.service.mode.privateBrowsing", 1);
      lockPref("network.trr.allow-rfc1918", true);
    '';
  };
}
