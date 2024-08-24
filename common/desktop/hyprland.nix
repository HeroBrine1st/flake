{ lib, pkgs, ... }: {
  programs.hyprland.enable = true;
  programs.dconf.enable = true;

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
        exec-once = [
          "${pkgs.swaynotificationcenter}/bin/swaync"

          # "${pkgs.xdg-desktop-portal-hyprland}/libexec/xdg-desktop-portal-hyprland" systemd-enabled
          # xdg-desktop-portal-gtk is also systemd-enabled, but may be disabled once gnome is removed

          "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
          "${pkgs.eww}/bin/eww" # https://github.com/elkowar/eww
        
          "hyprctl setcursor oreo_spark_purple_cursors 32"
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
      };
    };
  };
}
