{ pkgs, custom-pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    mangohud
    nodejs

    # Dash
    gnome-terminal
    nautilus
    # firefox-bin inferred from programs.firefox.enable
    ((element-desktop.override {
      # https://github.com/hardpixel/unite-shell/issues/371#issuecomment-2444667560
      commandLineArgs = lib.escapeShellArgs [ # element-desktop uses escapeShellArg internally but that's only for makeWrapper
        "--disable-features=WaylandWindowDecorations"
      ];
    }).overrideAttrs (prev: {
      patches = (prev.patches or []) ++ [
        ./patches/element-desktop-pass-disable-features.patch
      ];
    }))
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
    crosspipe
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
    custom-pkgs.jetbrains.idea-oss
    jetbrains.pycharm-oss
    jetbrains.webstorm
    jetbrains.clion gcc cmake
    arduino-ide
    jetbrains.rust-rover
    ((mistral-vibe.override {
      # remove textual-speedups as proprietary package
      # also to be used via ACP only
      python3Packages = python3Packages // {
        buildPythonApplication = old: let
          attrs = old finalAttrs;
          finalAttrs = attrs // {
            dependencies = builtins.filter (pkg: (lib.getName pkg) != "textual-speedups") attrs.dependencies;
            dontCheckRuntimeDeps = true;
          };
        in python3Packages.buildPythonApplication finalAttrs;
      };
    }).overrideAttrs(old: {
      patches = (old.patches or []) ++ [
        ./patches/mistral-vibe-enable-anthropic-cache.patch
      ];
    }))

    # "Office"
    libreoffice-fresh

    # "Games"
    # steam inferred by programs.steam.enable = true
    osu-lazer-bin
    custom-pkgs.tlauncher
    # CKAN not needed yet
    # protontricks not needed yet
    (pkgs.wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        obs-vkcapture
      ];
    })
    custom-pkgs.dreamfinity

    # "Security"
    seahorse # gnome

    # Other desktop applications
    chromium
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
    android-tools
  ];

  nixpkgs.allowedUnfreePackages = [
    "android-studio"
    "rust-rover"
    "webstorm"
    "clion"
    "steam" "steam-original" "steam-run" "steam-unwrapped"
    "osu-lazer-bin"
    "veracrypt"
    "code" "vscode"
    "winbox"
  ];

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

  programs.chromium = {
    enable = true;
    extraOpts = {
      "DefaultJavaScriptOptimizerSetting" = 2;
      "BlockThirdPartyCookies" = true;

      # TODO disable telemetry, https://qua3k.github.io/ungoogled/ implies it is possible but no settings or policies are found
    };
  };
}
