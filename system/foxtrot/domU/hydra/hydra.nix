{ ip, hydraURL, pkgs, config, ... }: {
  # so that parent is not world-writeable
  fileSystems."/nix/var/nix/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "mode=700" ];
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nix = {
    enable = true;
    settings = {
      experimental-features = [ "flakes" "nix-command" ];
      allowed-uris = [
        "github:"
        #"git+https://github.com/"
      ];
      build-dir = "/nix/var/nix/tmp/builds"; # so that it creates with right permissions
      max-jobs = 24;
    };
    buildMachines = [
      {
        hostName = "localhost";
        protocol = null;
        systems = [ "x86_64-linux" "aarch64-linux" "i686-linux" ];
        supportedFeatures = [ "nixos-test" "big-parallel" "benchmark" ];
        maxJobs = 24;
      }
    ];
    gc.automatic = true;
  };

  services = {
    hydra = {
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

      extraConfig = ''
        <githubstatus>
          jobs = .*
          useShortContext = true
        </githubstatus>
        Include /nix/persist/hydra.xml
      '';
    };
    nix-serve = {
      enable = true;
      secretKeyFile = "/nix/persist/cache.key";
      bindAddress = ip;
      openFirewall = false;
    };
  };

  networking.firewall.allowedTCPPorts = [
    config.services.hydra.port
    config.services.nix-serve.port
  ];
}