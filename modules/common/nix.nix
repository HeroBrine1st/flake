{ lib, config, systems, ... }: {
  options.nix.useFlakeCache = (lib.mkEnableOption "usage of cache from build machine") // { default = true; };

  config.nix.settings = lib.mkMerge [
    {
      auto-optimise-store = true;
      http-connections = 128;
      max-substitution-jobs = 128;
    }
    (lib.mkIf (config.network.overlay.enabled && config.nix.useFlakeCache) {
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
