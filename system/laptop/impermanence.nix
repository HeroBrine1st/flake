{ ... }: {
  environment.persistence."/nix/persist/system" = {
    hideMounts = true;
    directories = [
      "/var/log"
      { directory = "/var/tmp"; mode = "0777"; }
      { directory = "/var/lib/bluetooth"; mode = "0700"; }
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      { directory = "/etc/NetworkManager/system-connections"; mode = "0700"; }
      "/var/lib/sbctl"
      { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
      "/var/lib/libvirt"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  users.users.herobrine1st.hashedPasswordFile = "/nix/persist/password/herobrine1st";
  users.users.root.hashedPasswordFile = "/nix/persist/password/root";
  users.mutableUsers = false;

  network.overlay.configAppendixFile = "/nix/persist/nebula/local.yaml";
}
