{ flake, config, ... }: let
  ip = "10.135.116.10";
  domain = "hydra.ci.herobrine1st.ru";
  gconfig = config.virtualisation.xen.machines.hydra.system.config;
  attic = {
    domain = "cache.herobrine1st.ru";
    cache = "herobrine1st";
  };
in {
  virtualisation.xen.machines = {
    hydra = {
      modules = [
        flake.nixosModules.optionals
        flake.nixosModules.basic
        flake.inputs.impermanence.nixosModules.impermanence
        ./guest.nix
        ./hydra.nix
        ./attic.nix
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
        inherit attic;
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
        target = "/dev/asm/hydra";
        format = "raw";
      };
      extraXenlight = ''
        memory=8192
        vcpus=4
        cpu_weight=512
      '';
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers = {
      hydra = {
        entryPoints = [ "nebula" ];
        rule = "Host(`${domain}`)";
        service = "hydra";
      };
      atticDefaultCache = {
        entryPoints = [ "nebula" ];
        rule = "Host(`${attic.domain}`)";
        middlewares = [ "addAtticCachePrefix" ];
        service = "attic";
      };
      atticNamedCache = {
        entryPoints = [ "nebula" ];
        rule = "Host(`${attic.domain}`) && PathPrefix(`/${attic.cache}/`)";
        service = "attic";
      };
      atticApi = {
        entryPoints = [ "nebula" ]; # WARNING: HYDRA-BUILDER DOMU CAN EXFILTRATE JWT TOKEN - DON'T OPEN UNTIL XENSECRETS IS PROTECTED MORE
        rule = "Host(`${attic.domain}`) && PathPrefix(`/_api`)";
        service = "attic";
      };
    };
    middlewares = {
      addAtticCachePrefix.addPrefix.prefix = "/${attic.cache}";
    };
    services = {
      hydra.loadBalancer.servers = [ { url = "http://${ip}:${toString gconfig.services.hydra.port}"; } ];
      attic.loadBalancer.servers = [ { url = "http://${gconfig.services.atticd.settings.listen}"; } ];
    };
  };
}
