{ flake, ... }: {
  virtualisation.xen.machines = {
    forgejo-runner = {
      modules = [
        flake.nixosModules.optionals
        flake.nixosModules.basic
        flake.inputs.impermanence.nixosModules.impermanence
        ./guest.nix
        {
          fileSystems."/nix" = {
            device = "/dev/xvdb";
            fsType = "ext4";
            options = [ "defaults" ];
          };
        }
      ];
      networking.bridges.xenbr0 = {
        mac = "FE:FF:FF:00:00:02";
        ip = "10.135.116.11";
      };
      disks.xvdb = {
        # sudo qemu-img create -f qcow2 -o compression_type=zstd,nocow=on forgejo-runner.qcow2 256G
        # nix-shell -p libguestfs-with-appliance --run zsh
        # sudo guestfish -a forgejo-runner.qcow2
        # run
        # mkfs ext4 /dev/sda
        # Ctrl-D
        target = "/dev/asm/forgejo-runner";
        format = "raw";
      };
      extraXenlight = ''
        memory=16384
        vcpus=24
        cpu_weight=512
      '';
    };
  };
}