{ lib, pkgs, custom-pkgs, assets, ... }: let
  ags = pkgs.ags.override {
    # required for ags init -g 4
    extraPackages = [
      # pkgs.graphene # is not confirmed
      pkgs.gtk4
    ];
  };
in {
  imports = [
    ./hyprlock.nix
  ];

  programs.hyprland = {
    enable = true;
    # FIXME this drastically increases attack surface
    #       `uwsm run` allows any application to run any command outside of its namespace
    #       Most probably this command talks directly to PID 1 or user daemon, allowing restricting slice creation to everything except application launcher.
    withUWSM = true;
  };
  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = lib.mkForce [
      pkgs.xdg-desktop-portal-gtk # For both
      pkgs.xdg-desktop-portal-hyprland # For Hyprland
      pkgs.xdg-desktop-portal-gnome # For GNOME
    ];
  };

  systemd.user.services = let
    mkHyprlandService = service: {
      enable = true;
      wantedBy = [ "wayland-session@hyprland.target" ];
      requires = [ "wayland-wm@hyprland.target" ];
      after = [ "wayland-wm@hyprland.target" ];
    } // service;
    # A convenient replacement to exec-once which supports restarting on config changes
    mkSimpleHyprlandService = execStart: mkHyprlandService {
      serviceConfig.ExecStart = execStart;
    };
    mkOneshotHyprlandService = execStart: mkHyprlandService {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = execStart;
      };
    };
  in {
    hyprpolkitagent = mkSimpleHyprlandService "${pkgs.hyprpolkitagent}/libexec/v";
    hyprland-status-bar = mkSimpleHyprlandService "${custom-pkgs.topbar}/bin/topbar";
    hyprland-cursor = mkOneshotHyprlandService "hyprctl setcursor oreo_spark_purple_cursors 32";
    wl-clip-persist = mkSimpleHyprlandService "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular --all-mime-type-regex '^(?!x-kde-passwordManagerHint).+'";
    wlsunset = mkSimpleHyprlandService "${pkgs.wlsunset}/bin/wlsunset -l 51.7 -L 39.1";
    # uses systemd-run by default, no patch needed
    # https://github.com/H3rmt/hyprshell/blob/601c7eb1a61854d0d70b257447e9ddc044810855/exec-lib/src/run.rs#L57-L60
    hyprshell = mkSimpleHyprlandService "${custom-pkgs.hyprshell}/bin/hyprshell run";

    "gnome-terminal-server" = {
      environment = {
        # TODO remove close/minimize buttons via css when maximized (see unite extension)
        "XDG_CURRENT_DESKTOP" = "GNOME";
      };
      overrideStrategy = "asDropin";
    };
  };

  home-manager.users.herobrine1st = {
    wayland.windowManager.hyprland.systemd.enable = false;

    imports = [
      # plugins/hyprbar.nix
    ];

    dconf.settings = {
      "org/gnome/Terminal/Legacy/Settings" = {
        headerbar = true;
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        general = {
          resize_on_border = true;
          gaps_in = 0;
          gaps_out = 0;
        };

        input = {
          kb_layout = "us,ru";
          kb_options = "grp:alt_shift_toggle";
          sensitivity = "0.0";
          accel_profile = "flat";

          touchpad = {
            natural_scroll = true;
            disable_while_typing = true;
            tap-and-drag = true;
#            scroll_factor = 0.5;
          };

          follow_mouse = 0; # click on focus
        };

        decoration = {
          rounding = 4;

          blur = {
            enabled = true;
            xray = true;
            special = false;
            new_optimizations = true;
            size = 5;
            passes = 4;
            brightness = 1;
            noise = 1.0e-2;
            contrast = 1;
          };

          shadow = {
            enabled = false;
            range = 20;
            render_power = 2;
            ignore_window = true;
#            color = "rgba(0000001A)";
            offset = "0 2";
          };

          inactive_opacity = 0.5;
        };

        misc = {
          vfr = 1; # idk what is that
          vrr = 1;
          always_follow_on_dnd = true; # drag-on-drop follow focus

          focus_on_activate = false; # TODO forward such request to notification
        };

        exec-once = [
          # fix unite interfering with gtk
          "rm $HOME/.config/gtk-3.0/gtk.css"
          "rm $HOME/.config/gtk-4.0/gtk.css"
        ];

        bind = [
          "SUPER, 1, exec, uwsm app -- gnome-terminal"
#          "SUPER_SHIFT, A, exec, uwsm app -- ${pkgs.anyrun}/bin/anyrun" # https://github.com/anyrun-org/anyrun
          "SUPER, C, killactive, "
          "SUPER, up, fullscreenstate, 1"
          "SUPER, down, fullscreenstate, 0"
          "SUPER, L, exec, pidof hyprlock || hyprlock"
          #"ALT, Tab, cyclenext"
          #"ALT, Tab, bringactivetotop" # deprecated in favor of alterzorder, but it requires zheight. alterzorder can't replace bringactivetotop
        ];
        env = [
          "XCURSOR_THEME,oreo_spark_purple_cursors"
          "XCURSOR_SIZE,32"
        ];

        windowrule = [
          "float, class:(.*)"
          "noborder, class:(.*)"
        ];

        monitor = [
          ", preferred, auto, 1"
        ];
      };
    };

    services.hyprpaper = {
      enable = true;
      settings = {
        preload = [ "${assets + "/no-mans-sky-portal.png"}" ];
        wallpaper = [ ", ${assets + "/no-mans-sky-portal.png"}" ];
      };
    };

    systemd.user.services = {
      hyprpaper = {
        Install = {
          WantedBy = lib.mkForce [ "wayland-session@hyprland.target" ];
        };
        Unit = {
          Requires = [ "wayland-wm@hyprland.service" ];
          After = [ "wayland-wm@hyprland.service" ];
        };
      };
    };

    xdg.configFile = {
      "systemd/user/xdg-desktop-autostart.target".source = pkgs.emptyFile;
      "hyprshell".source = ./hyprshell;
    };
  };

  system.checks = [
    (pkgs.runCommand "check-hyprshell-config" {} ''
      ${custom-pkgs.hyprshell}/bin/hyprshell config check -c ${./hyprshell/config.toml} -s ${./hyprshell/styles.css}
      touch $out
    '')
  ];
}
