{ ... }: {
  programs.hyprlock.enable = true;

  home-manager.users.herobrine1st = {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
#          disable_loading_bar = true;
#          grace = 300;
#          hide_cursor = true;
#          no_fade_in = false;
        };

        background = [
          {
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
          }
        ];

        input-field = [
          {
            size = "200, 50";
            position = "0, -80";
            monitor = "";
            dots_center = true;
            fade_on_empty = false;
            font_color = "rgb(202, 211, 245)";
            inner_color = "rgb(91, 96, 120)";
            outer_color = "rgb(24, 25, 38)";
            outline_thickness = 4;
            placeholder_text = "\'Password...\'";
            shadow_passes = 2;
          }
        ];

        label = [
          # TIME
          {
              monitor = "";
              text = "$TIME"; # ref. https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/#variable-substitution
              font_size = 90;
              font_family = "$font";

              position = "-30, 0";
              halign = "right";
              valign = "top";
          }

          # DATE
          {
              monitor = "";
              text = "cmd[update:60000] date +\"%A, %d %B %Y\""; # update every 60 seconds
              font_size = 25;
              font_family = "$font";

              position = "-30, -150";
              halign = "right";
              valign = "top";
          }

          {
              monitor = "";
              text = "$LAYOUT[en,ru]";
              font_size = 24;
              onclick = "hyprctl switchxkblayout all next";

              position = "250, -20";
              halign = "center";
              valign = "center";
          }
        ];
      };
    };
  };
}