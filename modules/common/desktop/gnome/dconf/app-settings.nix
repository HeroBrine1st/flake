{ pkgs, ... }: {
  home-manager.users.herobrine1st = { lib, ... }: with lib.hm.gvariant; {
    dconf.settings = {
      "org/gnome/shell/weather" = {
        automatic-location = true;
      };

      "org/gnome/GWeather4" = {
        temperature-unit = "centigrade";
      };

      "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
        audible-bell = true;
        font = "JetBrains Mono 10";
        use-system-font = false;
        use-theme-colors = true;
        bold-is-bright = true;
      };

      "org/gnome/TextEditor" = {
        show-line-numbers = true;
        indent-style = "space";
        tab-width = mkUint32 2;
      };
    };
  };
}