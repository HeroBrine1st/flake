{ pkgs, config, lib, systems, ... }: {
  services.scrutiny.collector = lib.mkIf config.network.overlay.enabled {
    enable = true;

    settings = {
      host.id = config.networking.hostName;
      api.endpoint = "http://${systems.foxtrot.networks.overlay.address}:31821";

      # TODO it is possible to sandbox collector and use systemd-run (or socket-based application, anyway systemd stuff)
      #      to properly sandbox this colletor
      # https://github.com/AnalogJ/scrutiny/blob/49108bd1efabf206453455f9c20785a2d83f9a98/example.collector.yaml#L79-L83
    };

    schedule = "*:0/10";

    # pin version to review on upgrade
    package = let
      version = "0.8.1";
    in pkgs.scrutiny-collector.overrideAttrs {
      inherit version;
      pname = "scrutiny-collector";
      vendorHash = "sha256-SiQw6pq0Fyy8Ia39S/Vgp9Mlfog2drtVn43g+GXiQuI=";
      subPackages = "collector/cmd/collector-metrics"; # just in case

      src = pkgs.fetchFromGitHub {
        owner = "AnalogJ";
        repo = "scrutiny";
        rev = "refs/tags/v${version}";
        hash = "sha256-WoU5rdsIEhZQ+kPoXcestrGXC76rFPvhxa0msXjFsNg=";
      };

      # External direct dependencies as of 0.8.1
      # https://github.com/stretchr/testify
      # https://github.com/sirupsen/logrus
      # https://github.com/spf13/viper
      # https://github.com/mitchellh/mapstructure
      # https://github.com/jaypipes/ghw
    };
  };
}