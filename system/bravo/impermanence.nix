{ ... }: {
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
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"

      /*
        Network configuration - must be created manually (or you'll have problems if IP ever changes! Imperative configuration
        allows you to change it via remote desktop. Flakes, on other hand, require network (e.g. after nix-collect-garbage))
          [Match]
          Name=ens3

          [Network]
          Address=<v4 address>/<mask>
          Address=<v6 address>/<mask>
          Gateway=<v6 gateway if on same subnet>
          DNS=1.1.1.1
          DNS=1.0.0.1

          [Route]
          Gateway=10.0.0.1
          GatewayOnLink=true
        Or, better, replace GatewayOnLink with this:
          [Route]
          Destination=10.0.0.1/32
          Scope=link
        And Gateway can be moved under Network. This mirrors initial configuration.
      */
      "/etc/systemd/network/10-ens3.network" # REQUIRED ON INSTALLATION
    ];
  };

  users.users.herobrine1st.createHome = true;
  users.users.root.hashedPasswordFile = "/nix/persist/password/root"; # REQUIRED ON INSTALLATION
  users.mutableUsers = false;
}