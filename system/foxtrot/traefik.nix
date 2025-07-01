{ pkgs, modulesPath, lib, config, options, systems, ... }: let
  network = "traefik";
in {
  services.traefik = let
    dataDir = config.services.traefik.dataDir;
  in {
    # It is directly confirmed that containers are accessible from host by their IP address in docker network
    # https://github.com/moby/moby/discussions/49497
    # "Unpublished container ports continue to be directly accessible from the Docker host via the container's IP address.
    # If it is violated in docker 28, revert first commit after b93636678821afcdff87692416fd1980523d132e
    enable = true;
    group = "docker";
    # TODO combine nix and impermanence configs with yq-go
    dynamicConfigFile = "${dataDir}/dynamic.yml";
    environmentFiles = [
      "${dataDir}/traefik.env"
    ];
    staticConfigOptions = {
      providers.docker = {
        exposedByDefault = false;
        allowEmptyServices = true;
        inherit network;
      };
      certificatesResolvers.letsencrypt.acme = {
        email = "\${LETSENCRYPT_EMAIL}";
        storage = "${dataDir}/acme.json";
        dnsChallenge.provider = "\${DNS_PROVIDER}"; # requires corresponding environment variables
      };
      log = {
        format = "common";
        level = "INFO";
      };
      accessLog = {
        filePath = "${dataDir}/logs/access.log";
        format = "json";
        fields = {
          names.StartUTC = "drop";
          headers.names = {
            "CF-Connecting-IP" = "keep";
            "User-Agent" = "keep";
          };
        };
      };
      entryPoints = {
        https = {
          address = "\${PHYSICAL_INTERFACE_IP}:443";
          AsDefault = true;
          http2.maxConcurrentStreams = 250;
          http.tls = {}; # this enables TLS, idk whether it is still needed
          forwardedHeaders.trustedIPs = [ # TODO https://www.cloudflare.com/ips-v4/ , IFD is avoidable via staticConfigFile
            "173.245.48.0/20"
            "103.21.244.0/22"
            "103.22.200.0/22"
            "103.31.4.0/22"
            "141.101.64.0/18"
            "108.162.192.0/18"
            "190.93.240.0/20"
            "188.114.96.0/20"
            "197.234.240.0/22"
            "198.41.128.0/17"
            "162.158.0.0/15"
            "104.16.0.0/13"
            "104.24.0.0/14"
            "172.64.0.0/13"
            "131.0.72.0/22"
          ];
        };
        nebula = {
          address = "${systems."${config.networking.hostName}".networks.overlay.address}:443";
          http2.maxConcurrentStreams = 250;
          http.tls = {}; # this enables TLS, idk whether it is still needed
        };
      };
    };
  };

  systemd.services = {
    traefik = {
      after = [ "docker-traefik-network.service" ];
      requires = [ "docker-traefik-network.service" ];
    };
    docker-traefik-network = {
      wantedBy = [ "multi-user.target" ];
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "create-traefik-network" ''
          ${pkgs.docker}/bin/docker network inspect ${network} >/dev/null 2>&1 || \
          ${pkgs.docker}/bin/docker network create ${network}
        '';
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 443 ];
}