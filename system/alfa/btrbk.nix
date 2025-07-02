{ ... }: {
  services.btrbk = {
    instances = {
      "docker_data" = {
        onCalendar = "hourly";
        settings = {
          # stream_compress = "zstd";

          volume."/.fsroot" = { # base directory
            snapshot_create = "onchange";
            subvolume."@docker_data/*" = {
              target = "/mnt/basic/.fsroot/docker_data_snapshots/"; # btrfs send-receive target
              snapshot_dir = "@docker_data/snapshots/";
              snapshot_preserve = "24h 7d 4w";
              snapshot_preserve_min = "2d";
              target_preserve = "24h 7d 4w 12m 2y";
              target_preserve_min = "2d";
            };
            subvolume."@docker_definitions" = {
              target = "/mnt/basic/.fsroot/docker_definitions_snapshots/"; # btrfs send-receive target
              snapshot_dir = "snapshots/";
              snapshot_preserve = "24h 7d 4w";
              snapshot_preserve_min = "14d";
              target_preserve = "24h 7d 4w 12m 2y";
              target_preserve_min = "14d";
            };
          };
          volume."/mnt/arp" = {
            snapshot_create = "onchange";
            subvolume."@docker_data/*" = {
              snapshot_dir = "@docker_data/snapshots/";
              snapshot_preserve = "24h 7d 4w 12m 2y";
              snapshot_preserve_min = "14d";
            };
          };
        };
      };
      "basic" = {
        onCalendar = "daily";
        settings = {
          volume."/mnt/arp" = {
            snapshot_create = "onchange";
            subvolume."@basic" = {
              snapshot_dir = "snapshots/";
              snapshot_preserve = "24h 7d 4w 12m 2y";
              snapshot_preserve_min = "14d";
            };
          };
        };
      };
    };
  };

  users.users.btrbk = {
    extraGroups = [ "wheel" ];
  };
}
