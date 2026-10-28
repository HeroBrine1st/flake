{ flake, ... }: {
  virtualisation.xen.machines.forgejo-runner = {
    autoStart = false;
    modules = [
      flake.nixosModules.optionals
      flake.nixosModules.basic
      flake.inputs.impermanence.nixosModules.impermanence
      flake.nixosModules.xen.domain.onBtrfs
      flake.nixosModules.xen.secrets
      ./guest.nix
    ];
    specialArgs = {
      rootDevice = "/dev/xvdb";
      forgejoURL = "https://git.herobrine1st.ru";
    };
    networking.bridges.xenbr0 = {
      mac = "FE:FF:FF:00:00:02";
      ip = "10.135.116.11";
    };
    disks.xvdb = {
      target = "/dev/asm/forgejo-runner";
      format = "raw";
    };
    extraXenlight = ''
      memory=24576
      vcpus=24
      cpu_weight=512
    '';
  };
}
