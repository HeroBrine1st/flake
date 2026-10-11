{ ip, hydraURL, pkgs, config, lib, ... }: {
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
      substituters = [
        #"https://aseipp-nix-cache.global.ssl.fastly.net?priority=100" # not reliable, slows down builds
      ];
      build-dir = "/nix/var/nix/tmp/builds"; # so that it creates with right permissions
    };
    buildMachines = [
      {
        hostName = "localhost";
        protocol = null;
        systems = [ "x86_64-linux" "aarch64-linux" "i686-linux" ];
        supportedFeatures = [ "nixos-test" "big-parallel" "benchmark" ];
      }
    ];
    gc.automatic = true;
  };

  services = {
    hydra = {
      enable = true;
      # it was this patch in src/lib/Hydra/Plugin/GithubStatus.pm (see git blame)
      #-if ($eval->flake =~ m!github:([^/]+)/([^/]+)/([[:xdigit:]]{40})$! or $eval->flake =~ m!git\+ssh://git\@github.com/([^/]+)/([^/]+)\?.*rev=([[:xdigit:]]{40})$!) {
      #+if ($eval->flake =~ m!github:([^/]+)/([^/]+)/([[:xdigit:]]{40})(?:\?.*)?$! or $eval->flake =~ m!git\+ssh://git\@github.com/([^/]+)/([^/]+)\?.*rev=([[:xdigit:]]{40})$!) {
#      package = pkgs.hydra.overrideAttrs(old: {
#        patches = (old.patches or []) ++ [
#          ./hydra-ignore-query-params-in-flake-uri.patch
#        ];
#      });
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
