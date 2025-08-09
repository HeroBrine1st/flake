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

#      "org/gnome/shell/extensions/control-blur-effect-on-lockscreen" = {
#        brightness = 1.0;
#        sigma = 0;
#      };

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
        datemenu-hide-left-box = false;
        datemenu-hide-media-control = false;
        datemenu-hide-notifications = false;
        datemenu-hide-right-box = false;
        datemenu-remove-media-control = false;
        datemenu-remove-notifications = false;
        disable-adjust-content-border-radius = false;
        disable-remove-shadow = false;
        dnd-quick-toggle-enabled = false;
        input-show-selected = false;
        list-buttons = "[{\"name\":\"SystemItem\",\"title\":null,\"visible\":true},{\"name\":\"OutputStreamSlider\",\"title\":null,\"visible\":true},{\"name\":\"InputStreamSlider\",\"title\":null,\"visible\":false},{\"name\":\"St_BoxLayout\",\"title\":null,\"visible\":true},{\"name\":\"BrightnessItem\",\"title\":null,\"visible\":false},{\"name\":\"NMWiredToggle\",\"title\":\"Wired\",\"visible\":true},{\"name\":\"NMWirelessToggle\",\"title\":null,\"visible\":false},{\"name\":\"NMModemToggle\",\"title\":null,\"visible\":false},{\"name\":\"NMBluetoothToggle\",\"title\":null,\"visible\":false},{\"name\":\"NMVpnToggle\",\"title\":null,\"visible\":false},{\"name\":\"BluetoothToggle\",\"title\":\"Bluetooth\",\"visible\":true},{\"name\":\"PowerProfilesToggle\",\"title\":\"Power Mode\",\"visible\":true},{\"name\":\"NightLightToggle\",\"title\":\"Night Light\",\"visible\":true},{\"name\":\"DarkModeToggle\",\"title\":\"Dark Style\",\"visible\":true},{\"name\":\"KeyboardBrightnessToggle\",\"title\":\"Keyboard\",\"visible\":false},{\"name\":\"RfkillToggle\",\"title\":\"Aeroplane Mode\",\"visible\":false},{\"name\":\"RotationToggle\",\"title\":\"Auto Rotate\",\"visible\":false},{\"name\":\"ServiceToggle\",\"title\":\"GSConnect\",\"visible\":true},{\"name\":\"BackgroundAppsToggle\",\"title\":\"No Background Apps\",\"visible\":false},{\"name\":\"MediaSection\",\"title\":null,\"visible\":false}]";
        media-control-compact-mode = true;
        media-control-enabled = true;
        media-enabled = false;
        notifications-enabled = false;
        notifications-hide-when-no-notifications = true;
        notifications-integrated = false;
        notifications-use-native-controls = false;
        output-show-selected = false;
        user-removed-buttons = [ "RfkillToggle" ];
        volume-mixer-menu-enabled = false;
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

      "org/gnome/shell" = {
        enabled-extensions = [
          # Internal
          "auto-move-windows@gnome-shell-extensions.gcampax.github.com"

          # External
          "panel-corners@aunetx"
          "unite@hardpixel.eu"
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