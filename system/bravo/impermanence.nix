{ config, lib, ... }: {
  environment.persistence."/nix/persist/system" = {
    hideMounts = true;
    directories = [
      "/var/log"
      { directory = "/var/tmp"; mode = "0777"; }
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/cron"
      { directory = "/var/lib/docker"; mode = "0710"; }
      "/var/docker_data"
      "/home"
    ] ++ (if (config.services.traefik ? docker) && config.services.traefik.docker.enable || config.services.traefik.enable then [
      { directory = config.services.traefik.dataDir; user = "traefik"; inherit (config.services.traefik) group; }
    ] else []);
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  users.users.herobrine1st.createHome = true;
  users.users.root.hashedPasswordFile = "/nix/persist/password/root"; # REQUIRED ON INSTALLATION
  users.mutableUsers = false;

  network.overlay.configAppendixFile = "/nix/persist/nebula/local.yaml";
}