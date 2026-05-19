{ flake, ... }: {
  virtualisation.xen.machines = {
    forgejo-runner = {
      modules = [
        flake.nixosModules.optionals
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
        target = "/mnt/arp/@vm/images/forgejo-runner.qcow2";
        format = "qcow2";
      };
      extraXenlight = ''
        memory=32768
        vcpus=24
        cpu_weight=512
      '';
    };
  };
}