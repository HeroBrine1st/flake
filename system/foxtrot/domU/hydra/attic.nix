{ ip, attic, config, pkgs, ... }: let
  port = 8082;
in {
  services.atticd = {
    enable = true;
    # ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64=$(openssl rand -base64 32)
    environmentFile = "/var/lib/private/atticd/atticd.env";

    settings = rec {
      listen = "${ip}:${toString port}";
      # api-endpoint is deemed not to be more secure, esp. in the presence of allowed-hosts
      # api-endpoint protects against attacker who can change Host header, that same attacker can most probably change response too
      substituter-endpoint = "https://${attic.domain}/";
      allowed-hosts = [
        listen
        attic.domain
      ];

      storage = {
        type = "local";
        path = "/var/lib/atticd/storage";
      };

      database.url = "postgresql:///atticd?host=/run/postgresql&user=atticd";

      compression = {
        type = "zstd";
        level = 6;
      };

      garbage-collection = {
        interval = "12 hours";
        default-retention-period = "30 days";
      };
    };
  };

  services.impermanence.extraDirectories = [
    { directory = "/var/lib/private/atticd"; mode = "700"; }
  ];

  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "atticd";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ "atticd" ];
  };

  networking.firewall.allowedTCPPorts = [ port ];

  systemd.services = {
    # graceful shutdown in atticd waits for in-flight transfers with no deadline of its own
    atticd.serviceConfig.TimeoutStopSec = "15s";
    atticd-cache-init = {
      description = "Create the attic nix cache if it does not exist";
      wantedBy = [ "multi-user.target" ];
      requires = [ "atticd.service" ];
      after = [ "atticd.service" ];
      path = [ pkgs.curl pkgs.jq ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = let
        # atticd places wrapper there
        atticadm = "/run/current-system/sw/bin/atticd-atticadm";
      in ''
        set -euo pipefail
        url="http://${config.services.atticd.settings.listen}/_api/v1/cache-config/${attic.cache}"
        token=$(${atticadm} make-token \
          --sub cache-init --validity '5 minutes' \
          --pull '*' --create-cache '*' --configure-cache '*')
        code=$(curl -sS -o /dev/null -w '%{http_code}' \
          --retry 8 --retry-connrefused --retry-delay 1 \
          -H "authorization: Bearer $token" "$url")
        if [[ "$code" = 200 ]]; then
          echo "cache ${attic.cache} already exists"
          exit 0
        fi
        if [[ "$code" != 404 ]]; then
          echo "unexpected status $code from atticd" >&2
          exit 1
        fi
        payload=$(jq -n --arg keypair "$(cat /nix/persist/cache.key)" '{
          keypair: {Keypair: $keypair},
          is_public: true,
          store_dir: "/nix/store",
          priority: 30,
          upstream_cache_key_names: []
        }')
        curl -fsS --fail-with-body -X POST \
          -H "authorization: Bearer $token" -H "content-type: application/json" \
          -d "$payload" "$url"
        echo "created cache ${attic.cache}"
      '';
    };
  };
}
