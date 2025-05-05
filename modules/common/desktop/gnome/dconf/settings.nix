{ pkgs, assets, ... }: {
  home-manager.users.herobrine1st = { lib, ... }: with lib.hm.gvariant; {
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        cursor-size = 32;
        cursor-theme = "oreo_spark_purple_cursors";
        font-antialiasing = "rgba";
        font-hinting = "slight";
        gtk-theme = "Adwaita";
        icon-theme = "Arc-OSX-D";
        monospace-font-name = "JetBrains Mono 10";
        enable-hot-corners = true;
        accent-color = "orange";
      };

      "org/gnome/desktop/session" = {
        idle-delay = 300; # 0 to disable
      };

      "org/gnome/desktop/peripherals/mouse" = {
        accel-profile = "flat";
        left-handed = false;
        natural-scroll = false;
        speed = 0.0;
      };

      "org/gnome/desktop/peripherals/touchpad" = {
        two-finger-scrolling-enabled = true;
        tap-to-click = true;
      };

      "org/gnome/desktop/privacy" = {
        remove-old-trash-files = true;
        remove-old-temp-files = true;
        old-files-age = 7;
      };

      "org/gnome/desktop/wm/keybindings" = {
        show-desktop = [ "<Super>d" ];
        switch-input-source = [ "<Alt>Shift_L" "<Shift>Alt_L" "<Alt>Shift_R" "<Shift>Alt_R" "<Super>space" ];
      };

      "org/gnome/settings-daemon/plugins/power" = {
        power-button-action = "interactive";
      };

      "org/gnome/settings-daemon/plugins/media-keys" = {
        control-center = [ "<Super>i" ];
        custom-keybindings = [ "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Control><Alt>t";
        command = "gnome-terminal";
        name = "Launch terminal";
      };

      "org/gnome/desktop/wm/preferences" = {
        button-layout = "appmenu:minimize,close";
        focus-mode = "click";
      };

      "org/gnome/shell" = {
        favorite-apps = [ "org.gnome.Terminal.desktop" "org.gnome.Nautilus.desktop" "firefox.desktop" "element-desktop.desktop" "feishin.desktop" ];
      };

      "org/gnome/desktop/background" = {
        color-shading-type = "solid";
        picture-options = "zoom";
        picture-uri = "file://${assets + "/elite-dangerous-anaconda-in-the-blizzard.png"}";
        picture-uri-dark = "file://${assets + "/no-mans-sky-atlas.png"}";
        primary-color = "#000000000000";
        secondary-color = "#000000000000";
      };

      "org/gnome/desktop/input-sources" = {
        per-window = true;
        sources = [ (mkTuple [ "xkb" "us" ]) (mkTuple [ "xkb" "ru" ]) ];
        # xkb-options = [ "lv3:ralt_switch" "terminate:ctrl_alt_bksp" ];
      };

      "system/locale" = {
        region = "en_GB.UTF-8";
      };

      "org/gnome/mutter" = {
        dynamic-workspaces = true;
        edge-tiling = true;
      };
    };
  };
}