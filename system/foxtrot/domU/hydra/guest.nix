{ modulesPath, ... }: {
  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=25%" "mode=755" ];
    };
  };

  services.impermanence.enable = true;

  security.sudo-rs = {
    enable = true;
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  systemd.services."getty@hvc0".enable = true;

  systemd.network.enable = true;
  networking.useDHCP = true;
  networking.useNetworkd = true;

  users.users.herobrine1st = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMx6iwADwNH6wLURS6/jfa7mlKB9wXAPJaN8x61JainS herobrine1st@foxtrot"
    ];
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      AllowUsers = [ "herobrine1st" ];
    };
  };
}