{ config, lib, ... }: {
  services.impermanence = {
    enable = true;
    hideMounts = true;
    path = "/nix/persist/system";
    extraDirectories = [
      "/home"
    ];
  };

  users.users.herobrine1st = {
    createHome = true;
    password = "herobrine1st";
  };
  users.mutableUsers = false;
}