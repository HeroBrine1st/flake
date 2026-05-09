{ lib, pkgs, config, ... }: let
  cfg = config.virtualisation.xen;
  decodeDomain = pkgs.writeScript "decode-xl-domain" ''
    #!${pkgs.bash}/bin/bash

    ${pkgs.jq}/bin/jq --raw-output '.core' "$1"
    ${pkgs.jq}/bin/jq --raw-output '.base64' "$1" | ${pkgs.coreutils}/bin/base64 -d
    ${pkgs.jq}/bin/jq --raw-output '.extraXenlight' "$1"
  '';
  runDomain = pkgs.writeScript "run-xl-domain" ''
    #!${pkgs.bash}/bin/bash
    set -e

    if ${cfg.package}/bin/xl list "$1" 2>&1 > /dev/null; then
      ${stopDomain} $1
    fi

    cfg="/run/xen/domU-$1.cfg"
    rm -f "$cfg"
    ${decodeDomain} "$2" > "$cfg"
    ${cfg.package}/bin/xl create -Fc "$cfg"
  '';
  stopDomain = pkgs.writeScript "stop-xl-domain" ''
    #!${pkgs.bash}/bin/bash

    ${cfg.package}/bin/xl shutdown -w $1
    ${cfg.package}/bin/xl destroy $1
    rm -f "$cfg"
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

      serviceConfig = {
        ExecStart = "${runDomain} ${name} ${value.definition}";
        ExecStop = "${stopDomain} ${name}";
      };
    }) cfg.machines;
  };
}