{ flake, config, ... }: let
  ip = "10.135.116.10";
  domain = "hydra.ci.herobrine1st.ru";
  gconfig = config.virtualisation.xen.machines.hydra.system.config;
in {
  virtualisation.xen.machines = {
    hydra = {
      modules = [
        flake.nixosModules.optionals
        flake.inputs.impermanence.nixosModules.impermanence
        ./guest.nix
        ./hydra.nix
        {
          fileSystems."/nix" = {
            device = "/dev/xvdb";
            fsType = "ext4";
            options = [ "defaults" ];
          };
        }
      ];
      specialArgs = {
        inherit ip;
        hydraURL = "https://${domain}";
      };
      networking.bridges.xenbr0 = {
        mac = "FE:FF:FF:00:00:01";
        inherit ip;
      };
      disks.xvdb = {
        # sudo qemu-img create -f qcow2 -o compression_type=zstd,nocow=on hydra.qcow2 256G
        # nix-shell -p libguestfs-with-appliance --run zsh
        # sudo guestfish -a hydra.qcow2
        # run
        # mkfs ext4 /dev/sda
        # Ctrl-D
        target = "/mnt/arp/@vm/images/hydra.qcow2";
        format = "qcow2";
      };
      extraXenlight = ''
        memory=32768
        maxmem=32768
      '';
    };
  };

  services.traefik.dynamicConfigOptions.http = {
#    routers.nix-serve = {
#      entryPoints = [ "nebula" ];
#      rule = "Host(`cache.herobrine1st.ru`)";
#      middlewares = [ "nix-serve" ];
#      service = "nix-serve";
#    };
#    middlewares.nix-serve.compress = {
#      encodings = [ "zstd" "br" "gzip" ];
#    };
#    services.nix-serve.loadBalancer = {
#      servers = [ { url = "http://${ip}:${toString gconfig.services.nix-serve.port}"; } ];
#    };
    routers.hydra = {
      entryPoints = [ "nebula" ];
      rule = "Host(`${domain}`)";
      service = "hydra";
    };
    services.hydra.loadBalancer = {
      servers = [ { url = "http://${ip}:${toString gconfig.services.hydra.port}"; } ];
    };
  };
}