{ pkgs, modulesPath, lib, config, options, ... }: {
  services.traefik = {
    docker = {
      enable = true;
      network = "traefik";
      ports = [ "[::]:443:443" ];
    };
    group = "docker";
    dynamicConfigOptions = {
      tls = {
        certificates = [{
          certFile="${config.services.traefik.dataDir}/tls.cert";
          keyFile="${config.services.traefik.dataDir}/tls.key";
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
        exposedByDefault = false;
        allowEmptyServices = true;
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
          address = ":443";
          AsDefault = true;
          http2.maxConcurrentStreams = 250;
          http.tls = {};
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
}