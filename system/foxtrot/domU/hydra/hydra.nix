{ ip, hydraURL, pkgs, config, ... }: {
  nix.settings = {
    allowed-uris = [
      "github:"
      #"git+https://github.com/"
    ];
    build-dir = "/nix/var/nix/tmp/builds"; # so that it creates with right permissions
  };

  # so that parent is not world-writeable
  fileSystems."/nix/var/nix/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "mode=700" ];
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nix.buildMachines = [
    {
      hostName = "localhost";
      protocol = null;
      systems = [ "x86_64-linux" "aarch64-linux" "i686-linux" ];
      supportedFeatures = [ "nixos-test" "big-parallel" "benchmark" ];
    }
  ];

  services.hydra = {
    enable = true;
    package = pkgs.hydra.overrideAttrs(old: {
      patches = (old.patches or []) ++ [
        ./hydra-ignore-query-params-in-flake-uri.patch
      ];
    });
    inherit hydraURL;
    notificationSender = "hydra@localhost";
    useSubstitutes = true;
    listenHost = ip;
  };

  networking.firewall.allowedTCPPorts = [
    config.services.hydra.port
    config.services.nix-serve.port
  ];

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
    bindAddress = ip;
    openFirewall = false;
  };

  nix.gc = {
    automatic = true;
  };
}