{ ... }: {
  home-manager.users.herobrine1st = { lib, ... }: with lib.hm.gvariant; {
    dconf.settings = {
      "org/gnome/shell/extensions/system-monitor" = {
        battery-display = false;
        battery-time = false;
        center-display = false;
        compact-display = false;
        cpu-display = true;
        cpu-individual-cores = false;
        cpu-show-menu = true;
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
        fan-sensor-label = "nct6779 - 2";
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
        thermal-sensor-label = "nct6779 - TSI0_TEMP";
        thermal-show-text = false;
        thermal-style = "digit";
        thermal-threshold = 70;
        tooltip-delay-ms = 0;
      };
    };
  };
}