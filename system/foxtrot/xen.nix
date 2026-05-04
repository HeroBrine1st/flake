{ ... }: {
  boot.initrd.systemd.enable = true;

  virtualisation.xen = {
    enable = true;
    boot.params = [
      #"vga=ask"
      "dom0=pvh"
    ];
  };
}