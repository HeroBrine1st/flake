{ lib, pkgs, config, ... }: let
  cfg = config.virtualisation.xen;
  xl = "${cfg.package}/bin/xl";
  decodeDomain = pkgs.writeShellScript "decode-xl-domain" ''
    set -euo pipefail

    ${pkgs.jq}/bin/jq --raw-output '.core, (.cmdline | "cmdline=" + @sh)' "$1"
    ${pkgs.jq}/bin/jq --raw-output '.base64' "$1" | ${pkgs.coreutils}/bin/base64 -d
    ${pkgs.jq}/bin/jq --raw-output '.extraXenlight' "$1"
  '';
  runDomain = pkgs.writeShellScript "run-xl-domain" ''
    set -euo pipefail

    export PATH="${pkgs.qemu_xen}/bin:$PATH"
    cfg="/run/xen/domU-$1.cfg"

    if ${xl} list "$1" >/dev/null 2>&1; then
      ${stopDomain} "$1"
    fi
    rm -f "$cfg"
    ${decodeDomain} "$2" > "$cfg"
    exec ${xl} create -Fc "$cfg"
  '';
  stopDomain = pkgs.writeShellScript "stop-xl-domain" ''
    set -euo pipefail

    if ! ${xl} shutdown -ww "$1"; then
      echo "Graceful shutdown of domain $1 failed; forcing destruction" >&2

      if ${xl} list "$1" >/dev/null 2>&1; then
        ${xl} destroy "$1"
      else
        echo "Domain $1 is vanished. Okay" >&2
      fi
    fi
  '';
in {
  config = lib.mkIf cfg.enable {
    virtualisation.xen.domains.extraConfig = ''
      XENDOMAINS_SAVE=""
      XENDOMAINS_RESTORE=false
      XENDOMAINS_CREATE_USLEEP=1000000
    '';

    systemd.services = lib.mapAttrs' (name: value: lib.nameValuePair "xen-domU-${name}" {
      before = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];
      wants = [ "network.target" "xendomains.service" ];
      after = [ "network.target" "xendomains.service" ];
      restartIfChanged = true;

      serviceConfig = {
        ExecStart = "${runDomain} ${name} ${value.definition}";
        ExecStop = "${stopDomain} ${name}";
      };
    }) (lib.filterAttrs (name: value: value.autoStart) cfg.machines);

    virtualisation.xen.networking.bridges = lib.mkMerge (lib.mapAttrsToList (machine: machineCfg:
      lib.mapAttrs (bridge: bridgeCfg: {
        dhcp.reservations = [
          { inherit (bridgeCfg) ip mac; }
        ];
      }) machineCfg.networking.bridges
    ) cfg.machines);

    networking.hosts = lib.concatMapAttrs (machine: machineCfg:
      lib.concatMapAttrs (bridge: bridgeCfg: {
        "${machine}" = [ bridgeCfg.ip ];
      }) machineCfg.networking.bridges
    ) cfg.machines;
  };
}