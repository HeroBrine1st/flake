{ lib, config, ... }: let
  cfg = config.services.openssh;
  ports = cfg.ports;
in {
  options = {
    services.openssh.restrictToOverlay = lib.mkEnableOption "restrict service ports to overlay network";
  };

  config = lib.mkIf cfg.restrictToOverlay {
    assertions = [
      {
        assertion = config.network.overlay.enabled == true;
        message = "OpenSSH cannot be restricted to overlay network as it is not available on this machine";
      }
    ];
    warnings = lib.optional cfg.openFirewall "Opening firewall for OpenSSH conflicts with restricting it to overlay";

    services.openssh.openFirewall = false;
    networking.firewall.interfaces."nebula.overlay".allowedTCPPorts = cfg.ports;
    services.nebula.networks.overlay.firewall.inbound = map (port: {
      host = "any";
      port = toString port;
      proto = "any";
      group = "entryhost";
    }) cfg.ports;
  };
}