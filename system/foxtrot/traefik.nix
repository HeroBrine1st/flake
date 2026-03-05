{ pkgs, modulesPath, lib, config, options, systems, ... }: let
  network = "traefik";
in {
  services.traefik = let
    dataDir = config.services.traefik.dataDir;
  in {
    # It is directly confirmed that containers are accessible from host by their IP address in docker network
    # https://github.com/moby/moby/discussions/49497
    # "Unpublished container ports continue to be directly accessible from the Docker host via the container's IP address"
    # Now documented: https://docs.docker.com/reference/cli/docker/network/create/#internal , however only for internal networks
    # "and the host may communicate with any container IP directly"
    # (also a reason to finally use internal networks)
    enable = true;
    group = "docker";
    dynamicConfigOptions = {
      tls.options = builtins.mapAttrs (_: v: {
        sniStrict = true;
      } // v) {
        default = {};
        cloudflare.clientAuth = {
          clientAuthType = "RequireAndVerifyClientCert";
          caFiles = [
            (pkgs.fetchurl {
              url = "https://developers.cloudflare.com/ssl/static/authenticated_origin_pull_ca.pem";
              hash = "sha256-wU/tDOUhDbBxn+oR0fELM3UNwX1gmur0fHXp7/DXuEM=";
            })
          ];
        };
        dot.alpnProtocols = [ "dot" ];
      };
    };
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
      entryPoints = builtins.mapAttrs (_: v: {
        http.tls.certResolver = "letsencrypt";
      } // v) {
        https = {
          address = "\${PHYSICAL_INTERFACE_IP}:443";
          asDefault = true;
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
        # TODO rename to httpsOverlay
        nebula = {
          address = "${systems."${config.networking.hostName}".networks.overlay.address}:443";
          asDefault = true;
        };
        dot = {
          address = "\${PHYSICAL_INTERFACE_IP}:853";
          http.tls.options = "dot@file";
        };
        dotOverlay = {
          address = "${systems."${config.networking.hostName}".networks.overlay.address}:853";
          http.tls.options = "dot@file";
        };
      };
    };
  };

  services.logrotate = {
    settings = {
      "${config.services.traefik.dataDir}/logs/access.log" = {
        rotate = -1;
        postrotate = ''
          systemctl kill traefik --signal=USR1
        '';
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
        ExecStart = let
          docker = "${config.virtualisation.docker.package}/bin/docker";
        in pkgs.writeShellScript "create-traefik-network" ''
          set -e

          if ! ${docker} network inspect "${network}" &>/dev/null; then
            ${docker} network create --internal "${network}"
            exit 0
          fi

          if ${docker} network inspect -f '{{.Internal}}' "${network}" | grep -q '^true$'; then
            exit 0
          fi

          CONTAINERS=$(${docker} network inspect -f '{{range .Containers}}{{.Name}} {{end}}' "${network}")
          for c in $CONTAINERS; do
            ${docker} network disconnect "${network}" "$c" || true
          done

          failed=0
          { ${docker} network rm "${network}" && ${docker} network create --internal "${network}"; } || {
            echo "Failed to update docker network ${network}" >&2
            failed=1
          }

          for c in $CONTAINERS; do
            ${docker} network connect "${network}" "$c" || true
          done

          exit $failed
        '';
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 443 853 ];
}