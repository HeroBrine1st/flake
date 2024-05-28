{ config, pkgs, home-manager, custom-pkgs, ... }: {
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

    xdg.configFile."mimeapps.list".force = true;
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = "org.gnome.Nautilus.desktop";
        "x-scheme-handler/http" = ["firefox.desktop"];
        "x-scheme-handler/https" = ["firefox.desktop"];
        "x-scheme-handler/chrome" = ["firefox.desktop"];
        "text/html"= ["firefox.desktop"];
        "application/x-extension-htm" = ["firefox.desktop"];
        "application/x-extension-html" = ["firefox.desktop"];
        "application/x-extension-shtml" = ["firefox.desktop"];
        "application/xhtml+xml" = ["firefox.desktop"];
        "application/x-extension-xhtml" = ["firefox.desktop"];
        "application/x-extension-xht" = ["firefox.desktop"];
        "application/pdf" = ["firefox.desktop"];
        "image/png" = ["org.gnome.gThumb.desktop"];
        "image/jpeg" = ["org.gnome.gThumb.desktop"];
        "video/mp4" = ["mpv.desktop"];
        "image/webp" = ["org.gnome.gThumb.desktop"];
        "video/x-matroska" = ["vlc.desktop"];
        "text/plain" = ["org.gnome.TextEditor.desktop"];
        "video/webm"=["vlc.desktop"];
      };
      associations.added = {
        "x-scheme-handler/http" = ["firefox.desktop"];
        "x-scheme-handler/https" = ["firefox.desktop"];
        "x-scheme-handler/chrome" = ["firefox.desktop"];
        "text/html"= ["firefox.desktop"];
        "application/x-extension-htm" = ["firefox.desktop"];
        "application/x-extension-html" = ["firefox.desktop"];
        "application/x-extension-shtml" = ["firefox.desktop"];
        "application/xhtml+xml" = ["firefox.desktop"];
        "application/x-extension-xhtml" = ["firefox.desktop"];
        "application/x-extension-xht" = ["firefox.desktop"];
        "application/pdf" = ["firefox.desktop"];
        "x-scheme-handler/sms" = ["org.gnome.Shell.Extensions.GSConnect.desktop"];
        "x-scheme-handler/tel" = ["org.gnome.Shell.Extensions.GSConnect.desktop"];
        "image/png" = ["org.gnome.gThumb.desktop"];
        "image/jpeg" = ["org.gnome.gThumb.desktop"];
        "video/mp4" = ["mpv.desktop"];
        "image/webp" = ["org.gnome.gThumb.desktop"];
        "video/x-matroska" = ["vlc.desktop"];
        "text/plain" = ["org.gnome.TextEditor.desktop"];
        "video/webm"=["vlc.desktop"];
      };
    };

    xdg.configFile = {
      "MangoHud/MangoHud.conf".text = ''
        full
        font_glyph_ranges = cyrillic
      '';
      # bookmarks unshared
      "ptpython/config.py".source = ./ptpython-config.py;
    };

    home.file = {
      ".inputrc".text = ''
        set show-all-if-ambiguous on
        set bell-style audible
      '';
      ".face".source = ../../assets/avatar.png;
    };

    systemd.user = {
      enable = true;
      services = {
        "organise-screenshots" = {
          Install = {
            WantedBy = ["default.target"];
          };
          Service = {
            Type = "oneshot";
            ExecStart = ''${custom-pkgs.organise-files}/bin/organise-files.sh "''${HOME}/Pictures/Screenshots" "''${HOME}/Pictures/Screenshots" ; '' +
                        ''${custom-pkgs.organise-files}/bin/organise-files.sh "''${HOME}/Videos/Screencasts" "''${HOME}/Videos/Screencasts"'';
          };
        };
      };
    };

    services.arrpc.enable = true;
  };
}
