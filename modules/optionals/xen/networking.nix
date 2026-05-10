{ config, lib, ... }: let
  bridge = "xenbr0";
  cfg = config.virtualisation.xen.networking.bridges.${bridge};
in lib.mkIf cfg.enable {
  networking = {
    bridges.${bridge}.interfaces = [];
    interfaces.${bridge}.ipv4.addresses = [
      {
        inherit (cfg) prefixLength;
        address = cfg.gateway;
      }
    ];
    nat = {
      enable = true;
      internalInterfaces = [
        bridge
      ];
    };
    # it could be that it isn't needed
    firewall.interfaces.${bridge}.allowedUDPPorts = [ 67 ];
  };

  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [
          bridge
        ];
        # https://www.reddit.com/r/homelab/comments/1b4uob7/kea_dhcp_server_not_listening_when_started/
        service-sockets-max-retries = 200000;
        service-sockets-retry-wait-time = 1000;
      };
      subnet4 = [
        {
          id = 1;
          subnet = "${cfg.address}/${toString cfg.prefixLength}";
          pools = [
            { pool = cfg.dhcp.pool; }
          ];
          reservations = builtins.map (x: { hw-address = x.mac; ip-address = x.ip; }) cfg.dhcp.reservations;
          option-data = [
            {
              name = "routers";
              data = cfg.gateway;
            }
            {
              name = "domain-name-servers";
              data = cfg.dhcp.dns;
            }
          ];
        }
      ];
    };
  };
}