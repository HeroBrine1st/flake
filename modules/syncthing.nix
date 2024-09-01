{ config, lib, ... }: let
  # Remove this machine from config
  deviceIds = builtins.removeAttrs {
    "OPi5" = {
      id = "QDEHB5B-UGM2GQ6-3VG3RBL-JXOTGB2-OGNO5AL-H7KAFIC-MESTOWJ-O2YD3AO";
    };
    "MOBILE-DCV5AQD" = {
      id = "HLDBCKF-TWJF3WC-4VOPZPK-BHI4I3M-66HMB4M-3IJCFCB-ZBQVV4U-VEFL3AN";
    };
    "DESKTOP-IJK2GUG" = {
      id = "GLK2ETE-TUHZ43A-GAIRJYY-THAAOFO-GIAX7L5-DJO5NCF-NUN7GAR-DDGTZAM";
    };
    "lynx" = {
      id = "3HCNB6K-LJN74OU-TVIZNB4-RBWZA7T-JRPIMTW-6ZK5BRS-2WJEB5V-5AEVGQD";
    };
  } [ config.networking.hostName ];
  hostname = config.networking.hostName;
  mkRestricted = devices: folder: let
    enabled = builtins.elem hostname devices;
  in folder // {
    devices = lib.lists.remove hostname devices;
  };
in {
  services.syncthing = {
    user = "herobrine1st";
    configDir = "/home/herobrine1st/.config/Syncthing";
    overrideDevices = true;
    overrideFolders = false;
    settings = {
      devices = deviceIds;
      folders = {
        "uf77h-ptigu" = {
          label = "Secure";
          path = "/mnt/secure";
          devices = lib.lists.remove hostname [ "OPi5" "MOBILE-DCV5AQD" "DESKTOP-IJK2GUG" ];
        };
        "yb6rg-qs9gm" = {
          label = "Local Music";
          path = "/home/herobrine1st/Music/Main";
          devices = lib.lists.remove hostname [ "OPi5" "MOBILE-DCV5AQD" "DESKTOP-IJK2GUG" "lynx" ];
        };
        "f665p-sm9kf" = mkRestricted [ "MOBILE-DCV5AQD" "DESKTOP-IJK2GUG" "lynx"] {
          label = "Notes";
          path = "/home/herobrine1st/Documents/Notes";
        };
        "desktop" = mkRestricted [ "MOBILE-DCV5AQD" "DESKTOP-IJK2GUG" "lynx"] {
          label = "Desktop";
          path = "/home/herobrine1st/Desktop";
        };
      };
    };
  };
}
