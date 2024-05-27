{ ... }: {
  users.users.herobrine1st = {
    isNormalUser = true;
    description = "HeroBrine1st Erquilenne";
    extraGroups = [ "wheel" "docker" "libvirtd" "wireshark" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhbfIlo673pgcavZFZyKWoMf+Ak0ETfyD1Y89YJJnue solidexplorer@lynx"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMqqnT2Z4o9nZ81w9IbwYC6fkQvPfgGAwhgvBnp1VDWR herobrine1st@lynx"
    ];
  };
}