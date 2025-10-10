{ ... }: {
  services.impermanence = {
    enable = true;
    hideMounts = true;
    path = "/nix/persist/system";
    extraDirectories = [
      "/var/lib/sbctl"
    ];
  };

  users.users.herobrine1st.hashedPasswordFile = "/nix/persist/password/herobrine1st";
  users.users.root.hashedPasswordFile = "/nix/persist/password/root";
  users.mutableUsers = false;

  network.overlay.configAppendixFile = "/nix/persist/nebula/local.yaml";
}
