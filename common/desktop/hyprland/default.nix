{ lib, pkgs, custom-pkgs, ... }: let
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

  programs.hyprland.enable = true;
  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = lib.mkForce [
      pkgs.xdg-desktop-portal-gtk # For both
      pkgs.xdg-desktop-portal-hyprland # For Hyprland
      pkgs.xdg-desktop-portal-gnome # For GNOME
    ];
  };

  systemd.user.services."gnome-terminal-server" = {
    environment = {
      # TODO remove close/minimize buttons via css when maximized (see unite extension)
      "XDG_CURRENT_DESKTOP" = "GNOME";
    };
    overrideStrategy = "asDropin";
  };

  home-manager.users.herobrine1st = {
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

        # TODO move all that to systemd units (because exec-once does not track updates)
        #      https://github.com/Vladimir-csp/uwsm

        exec-once = [
          # "${pkgs.xdg-desktop-portal-hyprland}/libexec/xdg-desktop-portal-hyprland" systemd-enabled
          # xdg-desktop-portal-gtk is also systemd-enabled, but may be disabled once gnome is removed

          "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
          "${custom-pkgs.topbar}/bin/topbar"
        
          "hyprctl setcursor oreo_spark_purple_cursors 32"

          "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular --all-mime-type-regex '^(?!x-kde-passwordManagerHint).+'"

          "${pkgs.wlsunset}/bin/wlsunset -l 51.7164 -L 39.1849"
          
          # fix unite interfering with gtk
          "rm $HOME/.config/gtk-3.0/gtk.css"
          "rm $HOME/.config/gtk-4.0/gtk.css"

          # TODO https://github.com/H3rmt/hyprswitch
        ];

        bind = [
          "SUPER, 1, exec, gnome-terminal"
          "SUPER_SHIFT, A, exec, ${pkgs.anyrun}/bin/anyrun" # https://github.com/anyrun-org/anyrun
          "SUPER, C, killactive, "
          "SUPER, up, fullscreenstate, 1"
          "SUPER, down, fullscreenstate, 0"
          "ALT, Tab, cyclenext"
          "ALT, Tab, bringactivetotop" # deprecated in favor of alterzorder, but it requires zheight. alterzorder can't replace bringactivetotop
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
        preload = [ "${../../../assets/no-mans-sky-portal.png}" ];
        wallpaper = [ ", ${../../../assets/no-mans-sky-portal.png}" ];
      };
    };
  };
}
