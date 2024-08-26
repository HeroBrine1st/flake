{ pkgs, ... } : {
  wayland.windowManager.hyprland = {
    plugins = [
      pkgs.hyprlandPlugins.hyprbars
    ];
    settings = {
      plugin = {
        hyprbars = {
          bar_text_font = "Jetbrains Mono";
          bar_height = 30;
          bar_padding = 10;
          bar_button_padding = 5;
          bar_precedence_over_border = true;
          bar_part_of_window = true;

          bar_color = "rgba(1D1011FF)";
          col.text = "rgba(F7DCDEFF)";

          hyprbars-button = [
            "rgb(F7DCDE), 13, 󰖭, hyprctl dispatch killactive"
            "rgb(F7DCDE), 13, 󰖯, hyprctl dispatch fullscreen 1"
            "rgb(F7DCDE), 13, 󰖰, hyprctl dispatch movetoworkspacesilent special"
          ];
        };
      };
    };
  };


}