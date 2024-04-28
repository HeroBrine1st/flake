{ config, pkgs, home-manager, ... }: {
  home-manager.users.herobrine1st = {
    home.stateVersion = "23.11";
    programs.git = {
      enable = true;
      userName  = "herobrine1st";
      userEmail = "pankov.76.tvink@gmail.com";
    };

    xdg.desktopEntries = {
      "htop" = {
        name = "htop";
        noDisplay = true;
      };
    };

    xdg.configFile = {
      "MangoHud/MangoHud.conf" = ''
        full
        font_glyph_ranges = cyrillic
      '';
    };
  };
}
