{ ... }: let
  bridge = "xenbr0";
in {
  boot.initrd.systemd.enable = true;

  networking = {
    bridges.${bridge}.interfaces = [];
    interfaces.${bridge}.ipv4.addresses = [
      {
        address = "10.135.116.1";
        prefixLength = 24;
      }
    ];
    nat = {
      enable = true;
      internalInterfaces = [
        bridge
      ];
    };
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
          subnet = "10.135.116.0/24";
          pools = [
            { pool = "10.135.116.10-10.135.116.254"; }
          ];
          reservations = [
            { hw-address = "FE:FF:FF:00:00:01"; ip-address = "10.135.116.10"; }
          ];
          option-data = [
            {
              name = "routers";
              data = "10.135.116.1";
            }
            {
              name = "domain-name-servers";
              data = "1.1.1.1, 1.0.0.1";
            }
          ];
        }
      ];
    };
  };

  virtualisation.xen = {
    enable = true;
    boot.params = [
      #"vga=ask"
      "dom0=pvh"
    ];
    machines = {
      builder = {
        modules = [
          ./domU/builder
        ];
        extraXenlight = ''
          memory=1024
          vif=[ 'mac=FE:FF:FF:00:00:01,bridge=${bridge}' ]
        '';
      };
    };
    dom0Resources = {
      maxMemory = 120000;
      memory = 120000;
    };
  };
}