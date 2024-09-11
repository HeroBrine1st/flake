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
      { directory = "/var/lib/docker"; mode = "0710"; }
      "/etc/secureboot"
      { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
      { directory = "/mnt/secure"; user = "herobrine1st"; group = "users"; }
      "/var/lib/libvirt"
      { directory = "/var/lib/private/ollama"; mode = "700"; }
      { directory = "/var/lib/private/open-webui"; mode = "700"; }
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
