{ pkgs, config, systems, ... }: {
  environment.systemPackages = with pkgs; [
    (pkgs.callPackage ../../packages/edmarketconnector.nix {})
  ];

  environment.etc."htoprc".source = ./htoprc;

  services.llama-cpp.worker = {
    enable = true;
    host = "192.168.88.254";
    cache.enable = true;
  };

  services.displayManager.gdm.autoSuspend = false;

  networking.firewall = {
    allowedUDPPorts = [
      34197 # factorio
    ];
    extraCommands = ''
      iptables -A nixos-fw -p tcp -i enp9s0 --source 192.168.88.10 --dport ${toString config.services.llama-cpp.worker.port} -j nixos-fw-accept
    '';
  };
}
