{ config, lib, systems, ... }: let
  hostname = config.networking.hostName;
  cfg = config.services.syncthing;
  currentSystem = systems."${hostname}";
  mkFolder = folder: folder // {
    enable = builtins.elem hostname folder.devices; # Disable if restricted
    devices = lib.lists.remove hostname folder.devices; # Remove this machine from config
    # Place all folders in one directory if it is a server
    path = if currentSystem.isServer then "${cfg.dataDir}/${builtins.baseNameOf folder.path}" else folder.path;
  };
in {
  services.syncthing = lib.mkIf (currentSystem ? syncthing) {
    enable = true;
    user = lib.mkDefault "herobrine1st";
    configDir = lib.mkDefault "/home/herobrine1st/.config/Syncthing";
    overrideDevices = true;
    overrideFolders = lib.mkDefault false;
    settings = {
      devices = builtins.mapAttrs (k: v: v.syncthing) (builtins.removeAttrs (lib.attrsets.filterAttrs (k: v: v ? syncthing) systems) [hostname]);
      folders = {
        # TODO nothihg backs it up!
        "uf77h-ptigu" = mkFolder {
          label = "Secure";
          path = "/mnt/secure";
          devices = [ "foxtrot" "lynx" ];
        };
        "yb6rg-qs9gm" = mkFolder {
          label = "Local Music";
          path = "/home/herobrine1st/Music/Main";
          devices = [ "MOBILE-DCV5AQD" "DESKTOP-IJK2GUG" "lynx" ];
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
      22000
    ];
    allowedUDPPorts = [
      22000 21027
    ];
  };
}
