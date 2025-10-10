{ pkgs, ... }: {
  services.impermanence = {
    enable = true;
    hideMounts = true;
    path = "/nix/persist/system";
    extraDirectories = [
      "/var/lib/AccountsService" # TODO there are only two files there and none of them are secret
    ];
    extraFiles = [
      "/etc/keyfile/hdd.key"
      "/etc/keyfile/ssd.key"
    ];
  };

  users.users.herobrine1st.hashedPasswordFile = "/nix/persist/password/herobrine1st";
  users.users.root.hashedPasswordFile = "/nix/persist/password/root";
  users.mutableUsers = false;

  network.overlay.configAppendixFile = "/nix/persist/nebula/local.yaml";
}
