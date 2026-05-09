{ modulesPath, ... }: {
  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=25%" "mode=755" ];
    };
  };

  systemd.services."getty@hvc0".enable = true;

  systemd.network.enable = true;
  networking.useDHCP = true;
  networking.useNetworkd = true;

  users.users.herobrine1st = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "5GQQN4tUCccRcdno1zXbWzxpt0aACluLsiSM48HjPI36N4iTYk8qt0Z0AYWO4HOQ"; # test
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      AllowUsers = [ "herobrine1st" ];
    };
  };
}