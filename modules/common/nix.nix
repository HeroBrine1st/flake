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
        "foxtrot-cache:X8r3Ux9DlsIqkM0uMIw6gAlwCUCW324gm2VZn7eMJr0="
      ];
    })
  ];
}