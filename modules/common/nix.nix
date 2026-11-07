{ lib, config, systems, ... }: let
  cfg = config.flake.cache;
in {
  options = {
    flake.cache = {
      enable = (lib.mkEnableOption "usage of cache from build machine (if joined appropriate network)") // { default = true; };
      force = lib.mkEnableOption "lifting of appropriate network condition";
    };
  };

  config.nix.settings = lib.mkMerge [
    {
      auto-optimise-store = true;
      http-connections = 128;
      max-substitution-jobs = 128;
    }
    (lib.mkIf ((config.network.overlay.enabled || cfg.force ) && cfg.enable ) {
      substituters = [
        "https://cache.herobrine1st.ru"
      ];
      trusted-public-keys = [
        "cache.herobrine1st.ru-1:/NpJiVaEZpIfnL9k61h8ugyCdw3FH7IiMQVL80fXqyM="
        "foxtrot-cache:X8r3Ux9DlsIqkM0uMIw6gAlwCUCW324gm2VZn7eMJr0="
      ];
    })
  ];
}
