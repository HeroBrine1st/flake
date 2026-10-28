{ config, flake, ... }: let
  hydra = config.virtualisation.xen.machines.hydra;
in {
  virtualisation.xen.machines.hydra-builder = {
    autoStart = false;
    modules = [
      flake.nixosModules.optionals
      flake.nixosModules.basic
      flake.inputs.impermanence.nixosModules.impermanence
      flake.nixosModules.xen.domain.onBtrfs
      flake.nixosModules.xen.secrets
      ./guest.nix
      ./hydra-builder.nix
    ];
    specialArgs = {
      rootDevice = "/dev/xvdb";
      queueRunnerAddr = "http://${hydra.networking.bridges.xenbr0.ip}:${toString hydra.system.config.services.hydra.queueRunner.grpc.port}";
      atticListen = hydra.system.config.services.atticd.settings.listen;
      atticCache = hydra.specialArgs.attic.cache;
    };
    networking.bridges.xenbr0 = {
      mac = "FE:FF:FF:00:00:06";
      ip = "10.135.116.15";
    };
    disks.xvdb = {
      target = "/dev/asm/hydra-builder";
      format = "raw";
    };
    extraXenlight = ''
      memory=24576
      vcpus=24
      cpu_weight=512
    '';
  };
}
