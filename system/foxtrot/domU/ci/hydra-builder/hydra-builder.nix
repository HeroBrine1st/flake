{ queueRunnerAddr, atticListen, atticCache, pkgs, ... }: let
  endpoint = "http://${atticListen}";
in {
  services.hydra-builder = {
    enable = true;
    inherit queueRunnerAddr;
    authorizationFile = "/run/xen.secret/hydra-grpc-token";

    settings = {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "i686-linux"
      ];

      supportedFeatures = [
        "nixos-test"
        "big-parallel"
        "benchmark"
      ];

      maxJobs = 1;
    };
  };

  systemd.services = {
    hydra-builder = {
      requires = [ "xen-secrets.service" ];
      wants = [ "network-online.target" ];
      after = [ "xen-secrets.service" "network-online.target" ];
    };

    # hydra step involving anything on this domU -> hydra-builder -> nix build -> already built, nothing to do! -> hook skipped -> hydra presigns url -> oops
    # this service prevents that. Once, though, it's for bootstrapping.
    push-system = {
      requires = [ "xen-secrets.service" ];
      wants = [ "network-online.target" ];
      after = [ "xen-secrets.service" "network-online.target" ];
      requiredBy = [ "hydra-builder.service" ];
      before = [ "hydra-builder.service" ];
      environment.XDG_CONFIG_HOME = "/etc";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.attic-client}/bin/attic push ${atticCache} /run/current-system";
        DynamicUser = true;
      };
    };

    # this one pushes build closures (only substituted ones are affected but anyway)
    # and partial substitution attempts (i.e. 1000/2000 paths substituted and then boom power loss)
    watch-store = {
      requires = [ "xen-secrets.service" "nix-daemon.service" ];
      wants = [ "network-online.target" ];
      after = [ "xen-secrets.service" "network-online.target" "nix-daemon.service" ];
      requiredBy = [ "hydra-builder.service" ];
      before = [ "hydra-builder.service" ];
      environment.XDG_CONFIG_HOME = "/etc";

      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.attic-client}/bin/attic watch-store ${atticCache}";
        Restart = "always";
        RestartSec = 1; # accept some loss, it's inevitable anyway
        DynamicUser = true;
      };
    };
  };

  environment.etc."attic/config.toml".source = pkgs.writeText "attic-config.toml" ''
    default-server = "ci"

    [servers.ci]
    endpoint = "${endpoint}"
    token-file = "/run/xen.secret/attic-token"
  '';

  nix.settings = {
    # so overall problem is: queue-runner uses S3 to understand which paths are built and which aren't
    # we can push to attic from builder, we can bridge attic and hydra via proxy, but we can't make hydra know about attic
    #
    # This is the fix. On each build, attic push is done. That's it. Substitutions come with closure.
    # However, if this fails for any reason, a following hydra lookup (via proxy) will tell it that path is not in cache - then it will dispatch a presigned url
    # It's okay on it's own, except any retry on the same drv will mean... no hook run! So this is never fixed until builder is restarted
    #
    # Well, while true is the least evil, aside patching hydra-builder to include attic as dependency
    post-build-hook = pkgs.writeShellScript "attic-push" ''
      echo "Pushing build outputs $OUT_PATHS to cache"
      export XDG_CONFIG_HOME=/etc
      while true; do
        if ${pkgs.attic-client}/bin/attic push ${atticCache} $OUT_PATHS; then
          exit 0
        fi
        sleep 10
      done
      echo "Done pushing"
      exit 1
    '';
    substituters = [ "${endpoint}/${atticCache}?priority=0" ]; # xenbr0'd be faster
  };
}
