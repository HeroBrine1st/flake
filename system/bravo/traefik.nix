{ pkgs, modulesPath, lib, config, options, cloudflare-ips, ... }: let
  network = "traefik";
in {
  services.traefik = {
    enable = true;
    group = "docker";
    dynamicConfigFile = "${config.services.traefik.dataDir}/dynamic.yml";
    staticConfigOptions = {
      providers.docker = {
        exposedByDefault = false;
        allowEmptyServices = true;
        inherit network;
      };
      log = {
        format = "common";
        level = "INFO";
      };
      accessLog = {
        filePath = "${config.services.traefik.dataDir}/logs/access.log";
        format = "json";
        fields = {
          names = {
            StartUTC = "drop";
          };
          headers = {
            names = {
              "CF-Connecting-IP" = "keep";
              "User-Agent" = "keep";
            };
          };
        };
      };
      entryPoints = {
        https = {
          address = "[::]:443";
          AsDefault = true;
          http2.maxConcurrentStreams = 250;
          http.tls = {};
          forwardedHeaders.trustedIPs = cloudflare-ips;
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
          ${config.virtualisation.docker.package}/bin/docker network inspect ${network} >/dev/null 2>&1 || \
          ${config.virtualisation.docker.package}/bin/docker network create ${network}
        '';
      };
    };
  };

  networking.firewall.extraCommands = ''
    ip6tables -A nixos-fw -p tcp --dport 443 -j nixos-fw-accept
    ip6tables -A nixos-fw -p udp --dport 443 -j nixos-fw-accept
  '';

  assertions = [
    {
      assertion = config.networking.firewall.backend == "iptables";
      message = "Traefik module requires iptables firewall backend to open ports on v6 only";
    }
  ];
}