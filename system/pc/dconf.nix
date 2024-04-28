{ lib, ... }: with lib.hm.gvariant; {
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      cursor-size = 32;
      cursor-theme = "oreo_spark_purple_cursors";
      font-antialiasing = "rgba";
      font-hinting = "slight";
      gtk-theme = "Adwaita-dark";
      icon-theme = "Arc-OSX-D";
      monospace-font-name = "JetBrains Mono 10";
    };

    "org/gnome/shell/extensions/bedtime-mode" = {
      automatic-schedule = true;
      bedtime-mode-active = true;
      color-tone-preset = "grayscale";
      ondemand-button-visibility = "never";
    };

  #  "org/gnome/shell/extensions/blur" = {
  #    sigma = 0;
  #  };

    "org/gnome/shell/extensions/clipboard-indicator" = {
      cache-only-favorites = false;
      cache-size = 5;
      clear-history = [];
      disable-down-arrow = true;
      display-mode = 0;
      enable-keybindings = true;
      history-size = 200;
      keep-selected-on-clear = false;
      move-item-first = true;
      next-entry = [ "<Alt>x" ];
      notify-on-copy = false;
      pinned-on-bottom = false;
      prev-entry = [ "<Alt>z" ];
      preview-size = 30;
      strip-text = true;
      toggle-menu = [];
      topbar-preview-size = 15;
    };

    "org/gnome/shell/extensions/control-blur-effect-on-lockscreen" = {
      brightness = 1.0;
      sigma = 0;
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      apply-custom-theme = false;
      background-opacity = 0.8;
      click-action = "focus-minimize-or-previews";
      dash-max-icon-size = 64;
      dock-position = "BOTTOM";
      height-fraction = 0.9;
      hotkeys-show-dock = false;
      icon-size-fixed = false;
      intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
      preferred-monitor = -2;
      preferred-monitor-by-connector = "HDMI-1";
      show-mounts = false;
      show-trash = false;
    };

    "org/gnome/shell/extensions/panel-corners" = {
      force-extension-values = true;
    };

    "org/gnome/shell/extensions/quick-settings-tweaks" = {
      add-dnd-quick-toggle-enabled = false;
      datemenu-fix-weather-widget = true;
      datemenu-remove-media-control = false;
      datemenu-remove-notifications = false;
      disable-adjust-content-border-radius = false;
      disable-remove-shadow = false;
      input-show-selected = false;
      media-control-compact-mode = true;
      notifications-enabled = true;
      notifications-hide-when-no-notifications = true;
      notifications-use-native-controls = false;
      output-show-selected = false;
      user-removed-buttons = [ "RfkillToggle" ];
      volume-mixer-position = "top";
      volume-mixer-show-description = true;
      volume-mixer-show-icon = true;
    };

    "org/gnome/shell/extensions/system-monitor" = {
      battery-display = false;
      battery-time = false;
      center-display = false;
      compact-display = false;
      cpu-display = true;
      cpu-individual-cores = false;
      cpu-show-text = false;
      cpu-style = "digit";
      disk-display = false;
      disk-show-menu = true;
      disk-show-text = false;
      disk-style = "digit";
      disk-usage-style = "none";
      fan-display = false;
      fan-fan0-color = "#f2002eff";
      fan-refresh-time = 1000;
      fan-sensor-file = "/sys/class/hwmon/hwmon2/fan2_input";
      fan-show-menu = true;
      fan-show-text = false;
      fan-style = "digit";
      freq-display = false;
      freq-show-menu = false;
      freq-style = "graph";
      gpu-display = true;
      gpu-refresh-time = 1000;
      gpu-show-menu = true;
      gpu-show-text = false;
      gpu-style = "digit";
      icon-display = false;
      memory-display = true;
      memory-show-text = false;
      memory-style = "digit";
      move-clock = false;
      net-display = false;
      net-show-menu = true;
      net-show-text = false;
      show-tooltip = false;
      swap-display = false;
      thermal-display = true;
      thermal-fahrenheit-unit = false;
      thermal-refresh-time = 1000;
      thermal-sensor-file = "/sys/class/hwmon/hwmon1/temp1_input";
      thermal-show-text = false;
      thermal-style = "digit";
      thermal-threshold = 70;
      tooltip-delay-ms = 0;
    };

    "org/gnome/shell/extensions/unite" = {
      autofocus-windows = false;
      extend-left-box = false;
      greyscale-tray-icons = false;
      hide-app-menu-icon = false;
      hide-window-titlebars = "maximized";
      notifications-position = "center";
      show-appmenu-button = true;
      show-legacy-tray = true;
      use-activities-text = false;
      window-buttons-placement = "right";
    };

    "org/gnome/shell/weather" = {
      automatic-location = true;
    };

    "org/gnome/shell/world-clocks" = {
      locations = [ (mkVariant [ (mkUint32 2) (mkVariant [ "Vladivostok" "UHWW" true [ (mkTuple [ 0.752527801635986 2.3026710539800876 ]) ] [ (mkTuple [ 0.7527265771844955 2.30210867398851 ]) ] ]) ]) ];
    };

    "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
      audible-bell = true;
      font = "JetBrains Mono 10";
      use-system-font = false;
      use-theme-colors = true;
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

    "org/gnome/desktop/wm/keybindings" = {
      show-desktop = [ "<Super>d" ];
      switch-input-source = [ "<Alt>Shift_L" "<Shift>Alt_L" "<Alt>Shift_R" "<Shift>Alt_R" "<Super>space" ];
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,close";
      focus-mode = "click";
    };

    "org/gnome/shell/extensions/sp-tray" = {
      album-max-length = 174;
      artist-max-length = 145;
      display-format = "{track} by {artist} ({album})";
      display-mode = 0;
      hidden-when-inactive = true;
      hidden-when-paused = true;
      hidden-when-stopped = true;
      logo-position = 0;
      marquee-interval = 100;
      marquee-length = 180;
      marquee-tail = " |";
      metadata-when-paused = true;
      position = 2;
      title-max-length = 136;
    };

    "org/gnome/shell" = {
      enabled-extensions = [ "volume-mixer@evermiss.net" "tweaks-system-menu@extensions.gnome-shell.fifi.org" "sound-output-device-chooser@kgshank.net" "quick-settings-tweaks@qwreey" "system-monitor-next@paradoxxx.zero.gmail.com" "dash-to-dock@micxgx.gmail.com" "auto-move-windows@gnome-shell-extensions.gcampax.github.com" "primary_input_on_lockscreen@sagidayan.com" "ding@rastersoft.com" "panel-corners@aunetx" "gnomebedtime@ionutbortis.gmail.com" "unite@hardpixel.eu" "sp-tray@sp-tray.esenliyim.github.com" "gsconnect@andyholmes.github.io" "ControlBlurEffectOnLockScreen@pratap.fastmail.fm" "drive-menu@gnome-shell-extensions.gcampax.github.com" ];
      favorite-apps = [ "org.gnome.Terminal.desktop" "org.gnome.Nautilus.desktop" "firefox.desktop" "discord.desktop" "io.element.Element.desktop" "spotify.desktop" ];
    };

#    "org/gnome/shell/extensions/auto-move-windows" = {
#      application-list = [ "android-studio.desktop:2" "code-oss.desktop:2" "pycharm.desktop:2" "postman.desktop:2" "recaf.desktop:2" "jetbrains-webstorm.desktop:2" "idea.desktop:2" "jetbrains-idea.desktop:2" ];
#    };

    "org/gnome/desktop/app-folders" = {
      folder-children = [
        "Utilities"
        "aa652d2d-8719-4a40-835e-15ef770ac1c6"
        "d7db46c4-d38c-4c67-9869-e0e7aa7899c3"
        "85c4a776-29ea-4ff5-8f15-670e17e1fe62"
        "bd0b4f41-819e-4769-bbf2-f48d027bf961"
        "6fa7fcc2-aefd-4e1f-827c-cf4a6be704e5"
        "dd9876f1-0856-4470-8baf-a17a28f3b309"
        "75b80c76-a354-4910-a0de-1a76fd2eefeb"
        "87b23f92-4dfb-4de2-9e1a-d87353238049"
      ];
    };

    "org/gnome/desktop/app-folders/folders/6fa7fcc2-aefd-4e1f-827c-cf4a6be704e5" = {
      apps = [ "android-studio.desktop" "idea-ultimate.desktop" "webstorm.desktop" "clion.desktop" "arduino.desktop" "rust-rover.desktop" "idea-community.desktop" "code.desktop" ];
      name = "Development";
      translate = false;
    };

    "org/gnome/desktop/app-folders/folders/75b80c76-a354-4910-a0de-1a76fd2eefeb" = {
      apps = [ "steam.desktop" "osu!.desktop" "net.lutris.Lutris.desktop" "com.obsproject.Studio.desktop" ];
      name = "Games";
    };

    "org/gnome/desktop/app-folders/folders/85c4a776-29ea-4ff5-8f15-670e17e1fe62" = {
      apps = [ "org.gnome.gThumb.desktop" "vlc.desktop" "org.gnome.Totem.desktop" "org.musicbrainz.Picard.desktop" "mpv.desktop" "fr.handbrake.ghb.desktop" ];
      name = "Media";
      translate = false;
    };

    "org/gnome/desktop/app-folders/folders/87b23f92-4dfb-4de2-9e1a-d87353238049" = {
      apps = [ "veracrypt.desktop" "org.gnome.seahorse.Application.desktop" "org.keepassxc.KeePassXC.desktop" ];
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
      apps = [ "org.gnome.DiskUtility.desktop" "org.gnome.Calculator.desktop" "org.gnome.baobab.desktop" "org.gnome.FileRoller.desktop" "gparted.desktop" "org.gnome.Evince.desktop" "org.gnome.TextEditor.desktop" "org.gnome.Boxes.desktop" "gnome-nettool.desktop" ];
      name = "Utilities";
      translate = false;
    };

    "org/gnome/desktop/app-folders/folders/d7db46c4-d38c-4c67-9869-e0e7aa7899c3" = {
      apps = [ "org.gnome.Settings.desktop" "gnome-system-monitor.desktop" "OpenTabletDriver.desktop" "org.gnome.Extensions.desktop" "pavucontrol.desktop" "org.gnome.tweaks.desktop" "nvidia-settings.desktop" "org.gnome.Logs.desktop" "org.pipewire.Helvum.desktop" "com.github.wwmm.easyeffects.desktop" "ca.desrt.dconf-editor.desktop" ];
      name = "System Mainentance";
      translate = false;
    };

    "org/gnome/desktop/app-folders/folders/dd9876f1-0856-4470-8baf-a17a28f3b309" = {
      apps = [ "startcenter.desktop" "base.desktop" "calc.desktop" "draw.desktop" "impress.desktop" "math.desktop" "writer.desktop" ];
      name = "Office";
    };
  };
}