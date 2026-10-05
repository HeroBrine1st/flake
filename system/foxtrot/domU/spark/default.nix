{ flake, pkgs, utils, lib, ... }: {
  virtualisation.xen.machines = {
    spark = {
      type = "hvm"; # PCI passthrough requires HVM
      specialArgs = {
        rootDevice = "/dev/xvdx";
      };
      modules = [
        flake.nixosModules.optionals
        flake.nixosModules.basic
        flake.nixosModules.xen.domain.onBtrfs
        flake.inputs.impermanence.nixosModules.impermanence
        ./guest.nix
      ];
      networking.bridges.xenbr0 = {
        mac = "FE:FF:FF:00:00:05";
        ip = "10.135.116.14";
      };
      disks.xvdx = {
        # sudo qemu-img create -f qcow2 -o compression_type=zstd,nocow=on spark.qcow2 256G
        target = "/mnt/asm/@vm/images/spark.qcow2";
        format = "qcow2";
      };
      extraXenlight = ''
        memory=8192
        vcpus=14
        cpu_weight=256
        pci=[ "84:00.0@16,seize=1", "05:00.0@17,seize=1" ]
      '';
    };
  };
}