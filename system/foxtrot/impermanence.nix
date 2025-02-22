{ ... }: {
  environment.persistence."/nix/persist/system" = {
    hideMounts = true;
    directories = [
      "/var/log"
      { directory = "/var/tmp"; mode = "0777"; }
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/cron"
#      { directory = "/etc/NetworkManager/system-connections"; mode = "0700"; } empty as connected via ethernet
#      "/var/lib/AccountsService" is empty
#      { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; } headless
      { directory = "/var/lib/docker"; mode = "07100"; }
      "/var/docker_data"
      "/home"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  users.users.herobrine1st.hashedPasswordFile = "/nix/persist/password/herobrine1st";
  users.users.root.hashedPasswordFile = "/nix/persist/password/root";
  users.mutableUsers = false;
}