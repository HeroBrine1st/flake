{ pkgs, config, lib, systems, flake, ... }: {
  services.scrutiny.collector = lib.mkIf (config.network.overlay.enabled && config.boot.isBareMetal) {
    enable = true;

    settings = {
      host.id = config.networking.hostName;
      api.endpoint = "http://${systems.foxtrot.networks.overlay.address}:31821";

      # TODO it is possible to sandbox collector and use systemd-run (or socket-based application, anyway systemd stuff)
      #      to properly sandbox this colletor
      # https://github.com/AnalogJ/scrutiny/blob/49108bd1efabf206453455f9c20785a2d83f9a98/example.collector.yaml#L79-L83
    };

    schedule = "*:0/10";

    package = flake.pkgs.scrutiny-collector;
  };
}