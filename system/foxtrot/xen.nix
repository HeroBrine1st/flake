{ lib, ... }: let
  bridge = "xenbr0";
in {
  imports = [
    ./domU/hydra
    ./domU/forgejo-runner
    ./domU/general
    ./domU/letta-code
  ];
  config = {
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
        "dom0_mem=65536M,max:65536M"
        "smt=false"
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
    };
  };
}