{ pkgs, ... }: {
  # TODO: not that secret
  systemd.services.xen-secrets = {
    description = "Write xen.secret.* kernel parameters to /run/xen.secret";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    path = [ pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "xen.secret";
    };
    script = ''
      set -euo pipefail
      while read -r param; do
        if [[ ''${param} != xen.secret.*=* ]]; then
          continue
        fi
        name=$(basename -- "''${param#xen.secret.}")
        printf '%s\n' "''${name#*=}" > "/run/xen.secret/''${name%%=*}"
        chmod 0444 "/run/xen.secret/''${name%%=*}"
      done < <(tr ' ' '\n' < /proc/cmdline)
    '';
  };
}
