{ syncthing-devices, ... }: {
  services.syncthing = {
    enable = true;
    user = "herobrine1st";
    configDir = "/home/herobrine1st/.config/Syncthing";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      # TODO modularize with exclusion of current machine
      devices = {
        "OPi5" = syncthing-devices.opi5;
        "DESKTOP-IJK2GUG" = syncthing-devices.pc;
      };
      folders = {
        "uf77h-ptigu" = {
          label = "Secure";
          path = "/mnt/secure";
          devices = [ "OPi5" "DESKTOP-IJK2GUG" ];
        };
        "yb6rg-qs9gm" = {
          label = "Local Music";
          path = "/home/herobrine1st/Music/Main";
          devices = [ "OPi5" "DESKTOP-IJK2GUG" ];
        };
      };
    };
  };
}