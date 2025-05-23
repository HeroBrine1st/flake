{ config, lib, ... }: let
  deviceIds = {
    "alfa".id = "QDEHB5B-UGM2GQ6-3VG3RBL-JXOTGB2-OGNO5AL-H7KAFIC-MESTOWJ-O2YD3AO";
    "MOBILE-DCV5AQD".id = "HLDBCKF-TWJF3WC-4VOPZPK-BHI4I3M-66HMB4M-3IJCFCB-ZBQVV4U-VEFL3AN";
    "DESKTOP-IJK2GUG".id = "GLK2ETE-TUHZ43A-GAIRJYY-THAAOFO-GIAX7L5-DJO5NCF-NUN7GAR-DDGTZAM";
    "lynx".id = "3HCNB6K-LJN74OU-TVIZNB4-RBWZA7T-JRPIMTW-6ZK5BRS-2WJEB5V-5AEVGQD";
  };
  hostname = config.networking.hostName;
  mkFolder = folder: folder // {
    enable = builtins.elem hostname folder.devices; # Disable if restricted
    devices = lib.lists.remove hostname folder.devices; # Remove this machine from config
  };
in {
  services.syncthing = lib.mkIf (builtins.elem hostname (builtins.attrNames deviceIds)) {
    enable = true;
    user = "herobrine1st";
    configDir = "/home/herobrine1st/.config/Syncthing";
    overrideDevices = true;
    overrideFolders = false;
    settings = {
      devices = builtins.removeAttrs deviceIds [ hostname ]; # Remove this machine from config
      folders = {
        "uf77h-ptigu" = mkFolder {
          label = "Secure";
          path = "/mnt/secure";
          devices = [ "alfa" "MOBILE-DCV5AQD" "DESKTOP-IJK2GUG" ];
        };
        "yb6rg-qs9gm" = mkFolder {
          label = "Local Music";
          path = "/home/herobrine1st/Music/Main";
          devices = [ "alfa" "MOBILE-DCV5AQD" "DESKTOP-IJK2GUG" "lynx" ];
        };
        "f665p-sm9kf" = mkFolder {
          label = "Notes";
          path = "/home/herobrine1st/Documents/Notes";
          devices = [ "MOBILE-DCV5AQD" "DESKTOP-IJK2GUG" "lynx"];
        };
        "desktop" = mkFolder {
          label = "Desktop";
          path = "/home/herobrine1st/Desktop";
          devices = [ "MOBILE-DCV5AQD" "DESKTOP-IJK2GUG" "lynx"];
        };
      };
    };
  };

  networking.firewall = lib.mkIf config.services.syncthing.enable {
    allowedTCPPorts = [
      22000 # syncthing
    ];
    allowedUDPPorts = [
      22000 21027 # syncthing
    ];
  };
}
