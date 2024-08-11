{ lib, pkgs, ... }: {
  programs.hyprland.enable = true;

  home-manager.users.herobrine1st = {
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        input = {
          "kb_layout" = "us,ru";
          "kb_options" = "grp:alt_shift_toggle";
        };
        exec-once = [
          "${pkgs.swaynotificationcenter}/bin/swaync"

          # "${pkgs.xdg-desktop-portal-hyprland}/libexec/xdg-desktop-portal-hyprland" systemd-enabled
          # xdg-desktop-portal-gtk is also systemd-enabled, but may be disabled once gnome is removed

          "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
          "${pkgs.eww}/bin/eww"
        ];
      };
    };
  };
}