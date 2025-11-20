{ custom-pkgs, assets, lib, config, ... }: {
  users.users.herobrine1st = {
    isNormalUser = true;
    description = "HeroBrine1st Erquilenne";
    extraGroups = [ "wheel" "libvirtd" "wireshark" "adbusers" "dialout" ];
  };

  home-manager.users.herobrine1st = {
    home.stateVersion = "23.11";
    programs.git = {
      enable = true;
      settings = {
        user = {
          name  = "herobrine1st";
          email = "pankov.76.tvink@gmail.com";
        };
      };
    };

    xdg.desktopEntries = {
      "htop" = {
        name = "htop";
        noDisplay = true;
      };
      "jupyterlab" = {
        name = "jupyterlab";
        noDisplay = true;
      };
      "jupyter-notebook" = {
        name = "jupyter-notebook";
        noDisplay = true;
      };
    };

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
        "audio/flac"=["mpv.desktop"];
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
        "audio/flac"=["mpv.desktop"];
      };
    };

    xdg.configFile = {
      "MangoHud/MangoHud.conf".text = ''
        full
        font_glyph_ranges = cyrillic
      '';
      "gtk-3.0/bookmarks".text = ''
        file:///home/herobrine1st/Desktop
        file:///home/herobrine1st/Git
        file:///home/herobrine1st/Videos/OBS
        file:///.fsroot File System Root
        file:///tmp
        file:///mnt/tmp /mnt/tmp
        ${lib.optionalString (config.fileSystems ? "/mnt/extra") "file:///mnt/extra Extra"}
        ${lib.optionalString (config.fileSystems ? "/mnt/hdd") "file:///mnt/hdd HDD"}
        file:///home/herobrine1st/Documents
        file:///home/herobrine1st/Music
        file:///home/herobrine1st/Pictures
        file:///home/herobrine1st/Videos
        file:///home/herobrine1st/Downloads
        dav://10.168.88.10:3923/ Shared
      '';
      "ptpython/config.py".source = ./ptpython-config.py;
      "mimeapps.list".force = true;
      "gtk-3.0/bookmarks".force = true;
    };

    home.file = {
      ".face".source = assets + "/avatar.png";
      "Templates/Empty file".text = "";
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
  };
}
