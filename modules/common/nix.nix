{ lib, config, ... }: {
  nix.settings = lib.mkMerge [
    {
      auto-optimise-store = true;
    }
    (lib.mkIf config.network.overlay.enabled {
      substituters = [
        "http://10.168.88.10:5000"
      ];
      trusted-public-keys = [
        "foxtrot-cache:isnE29hG3jme1XXeNhOVNQ9AaO/gk6GgZBDUWVhwheM="
      ];
    })
  ];
}