{ ... }: {
  services.syncthing = {
    enable = true;
    user = "herobrine1st";
    configDir = "/home/herobrine1st/.config/Syncthing";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        "OPi5" = {
          id = "QDEHB5B-UGM2GQ6-3VG3RBL-JXOTGB2-OGNO5AL-H7KAFIC-MESTOWJ-O2YD3AO";
        };
        "MOBILE-DCV5AQD" = {
          id = "NUNTZPB-Z4CHNKA-3B3NF3Y-CREPZRK-P753FR3-WLMECWN-LGUDDN2-SB2ECQF";
        };
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