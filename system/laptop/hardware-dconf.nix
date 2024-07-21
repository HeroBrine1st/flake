{ ... }: {
  home-manager.users.herobrine1st = { lib, ... }: with lib.hm.gvariant; {
    dconf.settings = {
      "org/gnome/shell/extensions/system-monitor" = {
        battery-display = false;
        battery-hidesystem = false;
        battery-show-menu = true;
        battery-show-text = false;
        battery-time = true;
        center-display = false;
        compact-display = false;
        cpu-refresh-time = 1000;
        cpu-show-text = false;
        cpu-style = "digit";
        disk-display = false;
        disk-show-menu = true;
        disk-show-text = true;
        disk-usage-style = "none";
        fan-display = false;
        fan-style = "digit";
        freq-display = false;
        freq-show-text = false;
        freq-style = "digit";
        gpu-display = true;
        gpu-refresh-time = 1000;
        gpu-show-menu = true;
        gpu-show-text = false;
        gpu-style = "digit";
        icon-display = false;
        memory-show-text = false;
        memory-style = "digit";
        move-clock = false;
        net-display = false;
        show-tooltip = false;
        thermal-display = true;
        thermal-refresh-time = 1000;
        thermal-sensor-file = "/sys/class/hwmon/hwmon4/temp1_input";
        thermal-sensor-label = "k10temp - Tctl";
        thermal-show-menu = true;
        thermal-show-text = false;
        thermal-style = "digit";
      };
    };
  };
}
