{ pkgs, config, ... }: {
  services.hydra = {
    enable = true;
    hydraURL = "http://10.168.88.10:3000";
    notificationSender = "hydra@localhost";
    buildMachinesFiles = [];
    useSubstitutes = true;
    listenHost = "10.168.88.10";
  };

  networking.firewall.interfaces."nebula.overlay".allowedTCPPorts = [ config.services.hydra.port ];
}