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
            subvolume."@docker_data/forgejo" = {

            };
          };
        };
      };
    };
  };
}