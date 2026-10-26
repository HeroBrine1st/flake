{ lib, config, pkgs, ... }: let
  bridge = "xenbr0";
in {
  imports = [
    #./domU/hydra
    #./domU/forgejo-runner
    #./domU/general
    #./domU/letta-code
    #./domU/spark
  ];
  config = {
    nix.useFlakeCache = false;
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
        "dom0_mem=16384M,max:16384M"
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

    boot.loader.systemd-boot = let
      cfg = config.boot.loader.systemd-boot;
    in lib.mkIf (cfg.enable && cfg.bootCounting.enable && config.virtualisation.xen.enable) {
      # fix nixos entry being the preferred one
      extraInstallCommands = lib.mkAfter ''
        ${lib.getExe pkgs.gnused} -i 's/^preferred nixos-/preferred xen-/' "${config.boot.loader.efi.efiSysMountPoint}/loader/loader.conf"
      '';
    };
  };
}
