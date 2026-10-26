{ flake, pkgs, utils, lib, config, ... }: let
  ip = "10.135.116.14";
  domain = "spark.herobrine1st.ru";
  gconfig = config.virtualisation.xen.machines.spark.system.config;
in {
  virtualisation.xen.machines = {
    spark = {
      type = "hvm"; # PCI passthrough requires HVM
      specialArgs = {
        rootDevice = "/dev/xvdx";
        inherit ip;
      };
      modules = [
        flake.nixosModules.optionals
        flake.nixosModules.basic
        flake.nixosModules.xen.domain.onBtrfs
        flake.inputs.impermanence.nixosModules.impermanence
        ./guest.nix
        ./nvidia.nix
        ./docker.nix

        ./llama-swap.nix
      ];
      networking.bridges.xenbr0 = {
        mac = "FE:FF:FF:00:00:05";
        inherit ip;
      };
      disks.xvdx = {
        target = "/dev/asm/spark";
        format = "raw";
      };
      extraXenlight = ''
        memory=65536
        vcpus=28
        cpu_weight=256
        pci=[ "84:00.0@16,seize=1", "05:00.0@17,seize=1" ]
      '';
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.spark = {
      entryPoints = [ "nebula" ];
      rule = "Host(`${domain}`)";
      service = "spark";
    };
    services.spark.loadBalancer.servers = [ { url = "http://${ip}:${toString gconfig.services.llama-swap.port}"; } ];
  };
}
