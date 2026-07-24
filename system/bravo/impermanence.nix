{ config, lib, ... }: {
  services.impermanence = {
    enable = true;
    hideMounts = true;
    path = "/nix/persist/system";
    extraDirectories = [
      "/home"
    ];
    extraFiles = [
      /*
      [Match]
      Name=ens3

      [Network]
      Address=ip4/32 # it is set to /24 but /32 fits better I think. GatewayOnLink may be required if set to /32
      Gateway=ip4 but & /24 + 1
      DNS=1.1.1.1
      DNS=1.0.0.1
      DHCP=no

      Address=ip6/128
      DNS=2606:4700:4700::1111
      DNS=2606:4700:4700::1001

      [Route]
      Destination=::/0
      Gateway=ip6 but & /64 + 1
      GatewayOnLink=yes
      PreferredSource=ip6 # can have multiple addresses
      */
      "/etc/systemd/network/10-wan.network"
    ];
  };

  users.users.herobrine1st.createHome = true;
  users.users.root.hashedPasswordFile = "/nix/persist/password/root"; # REQUIRED ON INSTALLATION
  users.mutableUsers = false;

  network.overlay.configAppendixFile = "/nix/persist/nebula/local.yaml";
}