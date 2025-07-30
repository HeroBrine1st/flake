{ ... }: {
  services.btrbk = {
    instances = {
      "docker" = {
        onCalendar = "hourly";
        settings = {
          snapshot_create = "onchange";
          volume."/.fsroot" = {
            subvolume."@nix/persist/system/var/docker_data/*" = {
              snapshot_dir = "@archives/docker_data_ssd/";
              snapshot_preserve = "24h 7d 4w";
              snapshot_preserve_min = "2d";
              target = "/mnt/brp/@archives/docker_data_ssd/";
              target_preserve = "24h 7d 4w 12m 2y";
              target_preserve_min = "2d";
            };
            subvolume."@docker_compose" = {
              snapshot_dir = "@archives/docker_compose/";
              snapshot_preserve = "24h 7d 4w";
              snapshot_preserve_min = "14d";
              target = "/mnt/brp/@archives/docker_compose/";
              target_preserve = "24h 7d 4w 12m 2y";
              target_preserve_min = "14d";
            };
          };
          volume."/mnt/brp" = {
            subvolume."@docker_data/*" = {
              snapshot_dir = "@archives/docker_data_hdd/";
              snapshot_preserve = "24h 7d 4w 12m 2y";
              snapshot_preserve_min = "14d";
            };
          };
        };
      };
      "general" = {
        onCalendar = "hourly";
        settings = {
          snapshot_create = "onchange";
          volume."/mnt/brp" = {
            subvolume."@user" = {
              snapshot_dir = "@archives/user/";
              snapshot_preserve = "24h 7d 4w 12m 2y";
              snapshot_preserve_min = "14d";
            };
            subvolume."@media" = {
              snapshot_dir = "@archives/media/";
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
