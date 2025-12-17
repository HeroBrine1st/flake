{ pkgs, ... }: {
  home-manager.users.herobrine1st = { lib, ... }: with lib.hm.gvariant; {
    dconf.settings = {
      "org/gnome/desktop/app-folders" = {
        folder-children = [
          "Utilities"
          "aa652d2d-8719-4a40-835e-15ef770ac1c6"
          "d7db46c4-d38c-4c67-9869-e0e7aa7899c3"
          "85c4a776-29ea-4ff5-8f15-670e17e1fe62"
          "bd0b4f41-819e-4769-bbf2-f48d027bf961"
          "6fa7fcc2-aefd-4e1f-827c-cf4a6be704a5"
          "dd9876f1-0856-4470-8baf-a17a28f3b309"
          "75b80c76-a354-4910-a0de-1a76fd2eefeb"
          "87b23f92-4dfb-4de2-9e1a-d87353238049"
        ];
      };

      "org/gnome/desktop/app-folders/folders/6fa7fcc2-aefd-4e1f-827c-cf4a6be704a5" = {
        apps = [ "android-studio.desktop" "idea-ultimate.desktop" "pycharm-community.desktop" "webstorm.desktop" "clion.desktop" "arduino-ide.desktop" "rust-rover.desktop" "idea-community.desktop" "codium.desktop" ];
        name = "Development";
        translate = false;
      };

      "org/gnome/desktop/app-folders/folders/75b80c76-a354-4910-a0de-1a76fd2eefeb" = {
        apps = [ "steam.desktop" "osu!.desktop" "net.lutris.Lutris.desktop" "com.obsproject.Studio.desktop" "tlauncher.desktop" "dreamfinity.desktop" ];
        name = "Games";
      };

      "org/gnome/desktop/app-folders/folders/85c4a776-29ea-4ff5-8f15-670e17e1fe62" = {
        apps = [ "org.gnome.gThumb.desktop" "vlc.desktop" "org.gnome.Totem.desktop" "org.musicbrainz.Picard.desktop" "mpv.desktop" "fr.handbrake.ghb.desktop" ];
        name = "Media";
        translate = false;
      };

      "org/gnome/desktop/app-folders/folders/87b23f92-4dfb-4de2-9e1a-d87353238049" = {
        apps = [ "org.gnome.seahorse.Application.desktop" ];
        name = "Security";
        translate = false;
      };

      "org/gnome/desktop/app-folders/folders/Utilities" = {
        apps = [ "gnome-abrt.desktop" "gnome-system-log.desktop" "nm-connection-editor.desktop" "org.gnome.DejaDup.desktop" "org.gnome.Dictionary.desktop" "org.gnome.fonts.desktop" "org.gnome.Usage.desktop" "vinagre.desktop" ];
        categories = [ "X-GNOME-Utilities" ];
        excluded-apps = [ "org.gnome.tweaks.desktop" "org.gnome.baobab.desktop" "org.gnome.Connections.desktop" "org.gnome.DiskUtility.desktop" "org.gnome.Evince.desktop" "org.gnome.font-viewer.desktop" "org.gnome.Logs.desktop" "org.gnome.FileRoller.desktop" "org.gnome.Loupe.desktop" "org.gnome.seahorse.Application.desktop" "org.gnome.Console.desktop" ];
        name = "X-GNOME-Utilities.directory";
        translate = true;
      };

      "org/gnome/desktop/app-folders/folders/aa652d2d-8719-4a40-835e-15ef770ac1c6" = {
        apps = [ "org.gnome.Weather.desktop" "org.gnome.Calendar.desktop" "org.gnome.clocks.desktop" "org.gnome.Maps.desktop" "com.github.xournalpp.xournalpp.desktop" "org.kde.krita.desktop" ];
        name = "Personal";
        translate = false;
      };

      "org/gnome/desktop/app-folders/folders/bd0b4f41-819e-4769-bbf2-f48d027bf961" = {
        apps = [ "org.gnome.DiskUtility.desktop" "org.gnome.Calculator.desktop" "org.gnome.baobab.desktop" "org.gnome.FileRoller.desktop" "gparted.desktop" "org.gnome.Evince.desktop" "org.gnome.TextEditor.desktop" "virt-manager.desktop" "org.wireshark.Wireshark.desktop" "gnome-nettool.desktop" ];
        name = "Utilities";
        translate = false;
      };

      "org/gnome/desktop/app-folders/folders/d7db46c4-d38c-4c67-9869-e0e7aa7899c3" = {
        apps = [ "org.gnome.Settings.desktop" "gnome-system-monitor.desktop" "OpenTabletDriver.desktop" "org.gnome.Extensions.desktop" "org.pulseaudio.pavucontrol.desktop" "org.gnome.tweaks.desktop" "nvidia-settings.desktop" "org.gnome.Logs.desktop" "org.pipewire.Helvum.desktop" "com.github.wwmm.easyeffects.desktop" "ca.desrt.dconf-editor.desktop" ];
        name = "System Mainentance";
        translate = false;
      };

      "org/gnome/desktop/app-folders/folders/dd9876f1-0856-4470-8baf-a17a28f3b309" = {
        apps = [ "startcenter.desktop" "base.desktop" "calc.desktop" "draw.desktop" "impress.desktop" "math.desktop" "writer.desktop" ];
        name = "Office";
      };
    };
  };
}
