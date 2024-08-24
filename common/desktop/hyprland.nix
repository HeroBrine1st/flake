{ lib, pkgs, ... }: {
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

  home-manager.users.herobrine1st = {
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        input = {
          kb_layout = "us,ru";
          kb_options = "grp:alt_shift_toggle";
          sensitivity = "0.0";
          accel_profile = "flat";
        };

        # TODO move all that to systemd units (because exec-once does not track updates)

        exec-once = [
          "${pkgs.swaynotificationcenter}/bin/swaync"

          # "${pkgs.xdg-desktop-portal-hyprland}/libexec/xdg-desktop-portal-hyprland" systemd-enabled
          # xdg-desktop-portal-gtk is also systemd-enabled, but may be disabled once gnome is removed

          "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
          "${pkgs.eww}/bin/eww" # https://github.com/elkowar/eww
        
          "hyprctl setcursor oreo_spark_purple_cursors 32"

          "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular --all-mime-type-regex '^(?!x-kde-passwordManagerHint).+'"

          "${pkgs.wlsunset}/bin/wlsunset -l 51.7164 -L 39.1849"

          # TODO https://github.com/H3rmt/hyprswitch
        ];

        bind = [
          "SUPER, 1, exec, gnome-terminal"
          "SUPER_SHIFT, A, exec, ${pkgs.anyrun}/bin/anyrun" # https://github.com/anyrun-org/anyrun
          "SUPER, C, killactive, "
        ];
        env = [
          "XCURSOR_THEME,oreo_spark_purple_cursors"
          "XCURSOR_SIZE,32"
        ];

        windowrule = [
          "float, (.*)"
        ];
      };
    };

    services.hyprpaper = {
      enable = true;
      settings = {
        preload = [ "${../../assets/no-mans-sky-portal.png}" ];
        wallpaper = [ ", ${../../assets/no-mans-sky-portal.png}" ];
      };
    };
  };
}
