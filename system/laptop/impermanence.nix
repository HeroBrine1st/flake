{ ... }: {
  environment.persistence."/nix/persist/system" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/tmp"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  users.users.herobrine1st.hashedPasswordFile = "/nix/persist/password/herobrine1st";
  users.users.root.hashedPasswordFile = "/nix/persist/password/root";
  users.mutableUsers = false;
}