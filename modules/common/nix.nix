{ lib, config, ... }: {
  nix.settings = lib.mkIf config.network.overlay.enabled {
    substituters = [
      "http://10.168.88.10:5000"
    ];
    trusted-public-keys = [
      "foxtrot-cache:K5TJ723kF9QLxanfPFj0tHCHMEtKwnKkY56cAtOTg6Y="
    ];
  };
}