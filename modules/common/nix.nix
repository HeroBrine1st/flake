{ lib, config, systems, ... }: {
  options.nix.useFlakeCache = (lib.mkEnableOption "usage of cache from build machine") // { default = true; };

  config.nix.settings = lib.mkMerge [
    {
      auto-optimise-store = true;
    }
    (let
      host = "10.168.88.10";
    in lib.mkIf (config.network.overlay.enabled && config.nix.useFlakeCache && systems."${config.networking.hostName}".networks.overlay.address != host) {
      substituters = [
        "http://${host}:5000"
      ];
      trusted-public-keys = [
        "foxtrot-cache:X8r3Ux9DlsIqkM0uMIw6gAlwCUCW324gm2VZn7eMJr0="
      ];
    })
  ];
}