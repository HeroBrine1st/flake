{ pkgs, modulesPath, lib, config, options, ... }@host: let
  network = "traefik";
  traefikModule = lib.evalModules {
    modules = import (modulesPath + "/module-list.nix") ++ [
      ({ options, ...}: {
        # https://github.com/NixOS/nixpkgs/blob/26d499fc9f1d567283d5d56fcf367edd815dba1d/nixos/modules/virtualisation/nixos-containers.nix#L538-L541
        nixpkgs = if options.nixpkgs ? hostPlatform then
          { inherit (host.pkgs.stdenv) hostPlatform; }
        else
          { localSystem = host.pkgs.stdenv.hostPlatform; };
      })
      {
        # TODO simply copy from host and set enable=true
        services.traefik = {
          enable = true;
          dynamicConfigOptions = {
            tls = {
              certificates = [{
                certFile="${host.config.services.traefik.dataDir}/tls.cert";
                keyFile="${host.config.services.traefik.dataDir}/tls.key";
              }];

              # that's for cloudflare. the actual default (without cloudflare) is sniStrict=true only.
              options.default = {
                sniStrict = true;
                clientAuth = {
                  clientAuthType = "RequireAndVerifyClientCert";
                  caFiles = [ "${./cloudflare-origin-ca.pem}" ];
                };
              };
            };
          };
          staticConfigOptions = {
            providers.docker = {
              network = "${network}";
              exposedByDefault = false;
              allowEmptyServices = true;
            };
            log = {
              format = "common";
              level = "INFO";
            };
            accessLog = {
              filePath = "${host.config.services.traefik.dataDir}/logs/access.log";
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
                address = ":443";
                AsDefault = true;
                http2.maxConcurrentStreams = 250;
                forwardedHeaders.trustedIPs = [
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
            };
          };
        };
        system.stateVersion = host.config.system.stateVersion;
      }
    ];
  };
in {
  options = {
    services.traefik.docker = {
      enable = lib.mkEnableOption "traefik in docker";
      ports = lib.mkOption {
        type = with lib.types; listOf str;
        default = [];
        description = "Alias to virtualisation.oci-containers.containers.<name>.ports";
      };
    };

  };
  config = lib.mkIf config.services.traefik.docker.enable {
    virtualisation.oci-containers = {
      backend = "docker";
      containers = {
        traefik = assert !config.services.traefik.enable; {
          # do not build image, use /nix/store instead to reuse nixpkgs modules
          image = "almost-scratch";
          imageStream = pkgs.dockerTools.streamLayeredImage {
            name = "almost-scratch";
            tag = "latest";
          };
          volumes = [
            "/nix/store:/nix/store:ro"
            "/var/run/docker.sock:/var/run/docker.sock"
            "${config.services.traefik.dataDir}:${config.services.traefik.dataDir}"
            "/etc/passwd:/etc/passwd/:ro"
            "/etc/group:/etc/group:ro"
          ];
          entrypoint = "${pkgs.bash}/bin/bash";
          cmd = ["-c" "exec ${pkgs.su-exec}/bin/su-exec traefik:${config.services.traefik.group} ${traefikModule.config.systemd.services.traefik.serviceConfig.ExecStart}"];
          extraOptions = [
            "--network=${network}"
          ];
          inherit (config.services.traefik.docker) ports;
        };
      };
    };

    # TODO logrotate

    systemd.services = {
      docker-traefik = {
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

    users.users.traefik = {
      group = "traefik";
      home = config.services.traefik.dataDir;
      createHome = true;
      isSystemUser = true;
    };

    users.groups.traefik = {};
  };
}