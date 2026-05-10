{ ... }: let
  bridge = "xenbr0";
in {
  boot.initrd.systemd.enable = true;

  boot.kernel.sysctl = {
    "net.bridge.bridge-nf-call-ip6tables" = 0;
    "net.bridge.bridge-nf-call-iptables" = 0;
    "net.bridge.bridge-nf-call-arptables" = 0;
  };

  virtualisation.xen = {
    enable = true;
    boot.params = [
      #"vga=ask"
      "dom0=pvh"
    ];
    networking.bridges.xenbr0 = {
      enable = true;
      address = "10.135.116.0";
      prefixLength = 24;
      gateway = "10.135.116.1";
      dhcp = {
        dns = "1.1.1.1, 1.0.0.1";
        pool = "10.135.116.10-10.135.116.254";
      };
    };
    machines = {
      builder = {
        modules = [
          ./domU/builder
        ];
        networking.bridges.xenbr0 = {
          mac = "FE:FF:FF:00:00:01";
          ip = "10.135.116.10";
        };
        extraXenlight = ''
          memory=1024
        '';
      };
    };
    dom0Resources = {
      maxMemory = 120000;
      memory = 16384;
    };
  };
}