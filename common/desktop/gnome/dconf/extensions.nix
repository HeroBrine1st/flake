{ pkgs, ... }: {
  home-manager.users.herobrine1st = { lib, ... }: with lib.hm.gvariant; {
    dconf.settings = {
      "org/gnome/shell/extensions/bedtime-mode" = {
        automatic-schedule = true;
        bedtime-mode-active = true;
        color-tone-preset = "grayscale";
        ondemand-button-visibility = "never";
      };

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
        click-action = "focus-or-previews";
        dash-max-icon-size = 64;
        dock-position = "BOTTOM";
        height-fraction = 0.9;
        hotkeys-overlay = false;
        hotkeys-show-dock = false;
        icon-size-fixed = false;
        intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
        show-mounts = false;
        show-trash = false;
        show-icons-emblems = false;
        show-dock-urgent-notify = false;
        running-indicator-style = "DOTS";
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
        notifications-enabled = false;
        notifications-hide-when-no-notifications = true;
        notifications-use-native-controls = false;
        output-show-selected = false;
        user-removed-buttons = [ "RfkillToggle" ];
        volume-mixer-position = "top";
        volume-mixer-show-description = true;
        volume-mixer-show-icon = true;
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
        enabled-extensions = [
          # IDK what are those
          "volume-mixer@evermiss.net"
          "tweaks-system-menu@extensions.gnome-shell.fifi.org"
          "sound-output-device-chooser@kgshank.net"
          "ding@rastersoft.com"
          "gnomebedtime@ionutbortis.gmail.com"

          # Internal
          "auto-move-windows@gnome-shell-extensions.gcampax.github.com"

          # External
          "panel-corners@aunetx"
          "unite@hardpixel.eu"
          "sp-tray@sp-tray.esenliyim.github.com"
          "gsconnect@andyholmes.github.io"
          "ControlBlurEffectOnLockScreen@pratap.fastmail.fm"
          "drive-menu@gnome-shell-extensions.gcampax.github.com"
          "clipboard-indicator@tudmotu.com"
          "quick-settings-tweaks@qwreey"
          "system-monitor-next@paradoxxx.zero.gmail.com" # hardware-bound configuration, see systems
          "dash-to-dock@micxgx.gmail.com"
          "primary_input_on_lockscreen@sagidayan.com"
        ];
      };

  #    "org/gnome/shell/extensions/auto-move-windows" = {
  #      application-list = [ "android-studio.desktop:2" "code-oss.desktop:2" "pycharm.desktop:2" "postman.desktop:2" "recaf.desktop:2" "jetbrains-webstorm.desktop:2" "idea.desktop:2" "jetbrains-idea.desktop:2" ];
  #    };


    };
  };
}