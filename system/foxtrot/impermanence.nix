{ config, ... }: {
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
      { directory = "/var/lib/docker"; mode = "0710"; }
      "/var/docker_data"
      { directory = "/var/lib/hydra"; mode = "750"; user = "hydra"; group = "hydra"; }
      { directory = "/var/lib/postgresql"; mode = "750"; user = "postgres"; group = "postgres"; }
      { directory = "/var/lib/syncthing"; mode = "0700"; user = "syncthing"; group = "syncthing"; }
    ] ++ (if (config.services.traefik ? docker) && config.services.traefik.docker.enable || config.services.traefik.enable then [
      { directory = config.services.traefik.dataDir; user = "traefik"; inherit (config.users.users.traefik) group; }
    ] else []);
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

  network.overlay.configAppendixFile = "/nix/persist/nebula/local.yaml";
}