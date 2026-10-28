{ ip, attic, hydraURL, pkgs, config, lib, ... }: let
  package = pkgs.callPackage ./narinfoproxy/package.nix { };
  fakeBucket = "hydra-cache";
  proxyPort = 8083;
in {
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
    };
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
      queueRunner = {
        package = pkgs.hydra-queue-runner.overrideAttrs (old: {

          patches = (old.patches or []) ++ [
            ./patches/hydra-narinfo-presence-ttl.patch
            # we can't ignore it completely of course: it contains flake inputs and .drv files, at the very least
            ./patches/hydra-ignore-local-store.patch
        ];
        });
        grpc.address = ip;
        rest.address = ip;
        # TODO: alert on ntfy.sh when the proxy is down: hydra then counts every path as present and marks builds green unchecked
        #   journalctl -u hydra-queue-runner | grep "failed, skipping upload this cycle"
        # the proxy ignores the signature; any values in the file keep hydra from searching the EC2 metadata service
        awsCredentialsFile = builtins.toFile "aws-credentials" ''
          [default]
          aws_access_key_id = dummy
          aws_secret_access_key = dummy
        '';
        settings = {
          machineFreeFn = "DynamicWithMaxJobLimit";
          tokenPaths = [ "/nix/persist/tokens/hydra-grpc" ];
          remoteStoreAddr = [
            "s3://${fakeBucket}?endpoint=http://127.0.0.1:${toString proxyPort}&scheme=http"
          ];
          usePresignedUploads = true; # this makes hydra not fetch from builders, since they push to attic TODO disable them in hydra-builder
          useSubstitutes = false; # doesn't disable in hydra-builder, it works there
          maxUnsupportedTimeInS = 3155760000; # 100 years
          dispatchTriggerTimerInS = 15; # a machine joining doesn't wake the dispatcher immediately
        };
      };
    };
  };

  systemd.services = {
    hydra-evaluator.path = lib.mkBefore [
      (pkgs.nix-eval-jobs.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          # enable GC back
          substituteInPlace src/nix-eval-jobs.cc \
            --replace-fail 'setenv("GC_DONT_GC", "1", 1);' '''
        '';
      }))
    ];
    narinfo-proxy = {
      description = "Answer hydra store lookups from attic";
      bindsTo = [ "atticd.service" ];
      after = [ "network.target" "atticd.service" ];
      environment = {
        NARINFO_PROXY_UPSTREAM_CACHES = lib.concatStringsSep "," [
          "http://${config.services.atticd.settings.listen}/${attic.cache}"
          # don't make hydra build what's on cache.nixos.org - will be substituted by builder and pushed along with closure
          # it will be substituted even without this line, but this line fixes post-build-hook to run after EACH step
          "https://cache.nixos.org"
        ];
        NARINFO_PROXY_HOST = "127.0.0.1";
        NARINFO_PROXY_PORT = toString proxyPort;
      };
      serviceConfig = {
        ExecStart = "${package}/bin/narinfo-proxy";
        DynamicUser = true;
        Restart = "always";
      };
    };
    hydra-queue-runner = {
      bindsTo = [ "narinfo-proxy.service" ];
      after = [ "narinfo-proxy.service" ];
    };
  };

  # idk why DHCP doesn't keep up. Anyway
  systemd.sockets.hydra-queue-runner-grpc.socketConfig.FreeBind = true;
  systemd.sockets.hydra-queue-runner-rest.socketConfig.FreeBind = true;

  networking.firewall.allowedTCPPorts = [
    config.services.hydra.port
    config.services.hydra.queueRunner.rest.port
    config.services.hydra.queueRunner.grpc.port
  ];
}
