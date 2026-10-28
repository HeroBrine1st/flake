{ config, lib, pkgs, ... }: let
  hydra = config.virtualisation.xen.machines.hydra;
  builder = config.virtualisation.xen.machines.hydra-builder;
  runner = config.virtualisation.xen.machines.forgejo-runner;
  queueRunner = hydra.system.config.services.hydra.queueRunner;
  watcher = pkgs.callPackage ./watcher/package.nix { };
in {
  imports = [
    ./forgejo-runner
    ./hydra-builder
  ];

  systemd.services.ci-watchers = {
    description = "Run one CI domU at a time";
    wantedBy = [ "xendomains.service" ];
    partOf = [ "xendomains.service" ];
    wants = [ "network.target" "xendomains.service" ];
    after = [ "network.target" "xendomains.service" ];
    path = [ pkgs.lvm2.bin config.virtualisation.xen.package ];
    serviceConfig = {
      ExecStart = "${watcher}/bin/ci-watchers";
      Restart = "always";
      RestartSec = "15s";
      KillSignal = "SIGINT";
    };
    environment = {
      CI_FORGEJO_URL = runner.specialArgs.forgejoURL;
      CI_FORGEJO_ADMIN_TOKEN = "/etc/ci-swapper/tokens/forgejo-admin"; # forgejo token with admin scope
      CI_HYDRA_REST = "http://${queueRunner.rest.address}:${toString queueRunner.rest.port}";
      CI_HYDRA_GRPC_TOKEN = "/etc/ci-swapper/tokens/hydra-grpc"; # one of services.hydra.queueRunner.settings.tokenPaths files
      CI_ATTIC_CACHE = hydra.specialArgs.attic.cache;
      CI_ATTIC_JWT_SECRET = "/etc/ci-swapper/tokens/attic-jwt-secret"; # same as ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64 in hydra domU
      CI_LOG_LEVEL = "DEBUG";
      CI_BUILDER__DOMAIN = "hydra-builder";
      CI_BUILDER__DEFINITION = "${builder.definition}";
      CI_BUILDER__LV = "${builder.disks.xvdb.target}";
      CI_BUILDER__LV_SIZE = "256G";
      CI_BUILDER__THIN_POOL = "asm-thin";
      CI_RUNNER__DOMAIN = "forgejo-runner";
      CI_RUNNER__DEFINITION = "${runner.definition}";
      CI_RUNNER__LV = "${runner.disks.xvdb.target}";
      CI_RUNNER__LV_SIZE = "256G";
      CI_RUNNER__THIN_POOL = "asm-thin";
      CI_RUNNER__LABELS = lib.concatMapStringsSep "," (label: builtins.head (lib.splitString ":" label)) runner.system.config.services.forgejo-runner.instances.main.settings.runner.labels;
    };
  };

  services.impermanence.extraDirectories = [
    "/etc/ci-swapper/tokens"
  ];
}
