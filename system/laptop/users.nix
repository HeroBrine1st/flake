{ ... }: {
  users.users.herobrine1st = {
    isNormalUser = true;
    description = "HeroBrine1st Erquilenne";
    extraGroups = [ "wheel" "docker" "libvirtd" "wireshark" ];
    # Same but hardened - no authorized_keys at all
  };

  services.openssh.enable = false;
}