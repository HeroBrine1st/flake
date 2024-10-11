{ ... }: {
  services.btrbk = {
    instances = {
      "docker_data" = {
        #onCalendar = "daily";
        onCalendar = null;
        settings = {
          # stream_compress = "zstd";

          volume."/.fsroot" = { # base directory
            target = "/mnt/basic/.fsroot/docker_data_snapshots/"; # btrfs send-receive target
            snapshot_dir = "@docker_data/snapshots/";
            snapshot_preserve = "12h 7d 4w 12m 2y";
            snapshot_preserve_min = "2d";
            target_preserve = "12h 7d 4w 12m 2y";
            target_preserve_min = "2d";
            subvolume."@docker_data/*" = {

            };
          };
        };
      };
    };
  };
}