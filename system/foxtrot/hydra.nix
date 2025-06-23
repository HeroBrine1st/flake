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
      maxJobs = 32;
    }
  ];

  services.hydra = {
    enable = true;
    package = pkgs.hydra.overrideAttrs(old: {
      patches = (old.patches or []) ++ [
        ./hydra-ignore-query-params-in-flake-uri.patch
      ];
    });
    hydraURL = "http://10.168.88.10:3000";
    notificationSender = "hydra@localhost";
    useSubstitutes = true;
    listenHost = "10.168.88.10";
  };

  services.hydra.extraConfig = ''
    <githubstatus>
      jobs = .*
      useShortContext = true
    </githubstatus>
    Include /nix/persist/hydra.xml
  '';

  services.nix-serve = {
    enable = true;
    secretKeyFile = "/nix/persist/foxtrot-cache.key";
    bindAddress = "10.168.88.10";
    openFirewall = false;
  };

  services.nebula.networks.overlay.firewall.inbound = [
    {
      host = "any";
      port = toString config.services.nix-serve.port;
      proto = "any";
    }
  ];

  networking.firewall.interfaces."nebula.overlay".allowedTCPPorts = [
    config.services.hydra.port
    config.services.nix-serve.port
  ];
}