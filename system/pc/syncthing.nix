{ syncthing-devices, ... }: {
  services.syncthing = {
    enable = true;
    user = "herobrine1st";
    configDir = "/home/herobrine1st/.config/Syncthing";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        "OPi5" = syncthing-devices.opi5;
        "MOBILE-DCV5AQD" = syncthing-devices.laptop;
      };
      folders = {
        "uf77h-ptigu" = {
          label = "Secure";
          path = "/mnt/secure";
          devices = [ "OPi5" "MOBILE-DCV5AQD" ];
        };
        "yb6rg-qs9gm" = {
          label = "Local Music";
          path = "/home/herobrine1st/Music/Main";
          devices = [ "OPi5" "MOBILE-DCV5AQD" ];
        };
      };
    };
  };
}