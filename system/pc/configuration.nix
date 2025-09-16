{ pkgs, config, systems, ... }: {
  environment.systemPackages = with pkgs; [
    (pkgs.callPackage ../../packages/edmarketconnector.nix {})
  ];

  environment.etc."htoprc".source = ./htoprc;

  nix.settings = {
    substituters = [
      "https://cuda-maintainers.cachix.org"
    ];
    trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  services.llama-cpp.worker = {
    enable = true;
    host = systems."${config.networking.hostName}".networks.overlay.address;
    cache.enable = true;
  };

  networking.firewall.allowedUDPPorts = [
    34197 # factorio
  ];
  
  networking.firewall.interfaces."nebula.overlay".allowedTCPPorts = [ config.services.llama-cpp.worker.port ];
  services.nebula.networks.overlay.firewall.inbound = [
    {
      host = "foxtrot";
      port = toString config.services.llama-cpp.worker.port;
      proto = "tcp";
    }
  ];
}
