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
        file:///mnt/extra Extra
        file:///mnt/hdd HDD
        file:///home/herobrine1st/.minecraftlauncher/Dreamfinity
        file:///home/herobrine1st/.minecraft/home Minecraft Home
        file:///home/herobrine1st/Documents
        file:///home/herobrine1st/Music
        file:///home/herobrine1st/Pictures
        file:///home/herobrine1st/Videos
        file:///home/herobrine1st/Downloads
        sftp://192.168.88.72/mnt/basic Seagate Basic on Orange Pi 5
      '';
    };

    home.file = {
      "Pictures/Wallpapers/no-mans-sky-atlas.png" = {
        source = ../../wallpapers + "/no-mans-sky-atlas.png";
        enable = false;
      };
      ".inputrc".text = ''
        set show-all-if-ambiguous on
        set bell-style audible
      '';
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


    imports = [
      ./dconf.nix
      ./dconf-pc.nix
    ];
  };
}
