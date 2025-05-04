{ pkgs, config, ... }: {
  nix.settings.allowed-uris = [
    "github:"
#    "git+https://github.com/"
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nix.buildMachines = [
    {
      hostName = "localhost";
      protocol = null;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      # I am a 'x86_64-linux' with features {benchmark, big-parallel, kvm, nixos-test}
      supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
    }
  ];

  services.hydra = {
    enable = true;
    hydraURL = "http://10.168.88.10:3000";
    notificationSender = "hydra@localhost";
    useSubstitutes = true;
    listenHost = "10.168.88.10";
  };

  networking.firewall.interfaces."nebula.overlay".allowedTCPPorts = [ config.services.hydra.port ];
}