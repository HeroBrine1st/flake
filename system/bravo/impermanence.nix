{ config, lib, ... }: {
  services.impermanence = {
    enable = true;
    hideMounts = true;
    path = "/nix/persist/system";
    extraDirectories = [
      "/home"
    ];
  };

  users.users.herobrine1st.createHome = true;
  users.users.root.hashedPasswordFile = "/nix/persist/password/root"; # REQUIRED ON INSTALLATION
  users.mutableUsers = false;

  network.overlay.configAppendixFile = "/nix/persist/nebula/local.yaml";
}