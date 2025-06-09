let
  guiPort = 8384;
in {
  services.syncthing = {
    configDir = "/var/lib/syncthing/config";
    dataDir = "/var/lib/syncthing/folders";
    overrideFolders = true;
    guiAddress = "10.168.88.72:${builtins.toString guiPort}";
  };

  networking.firewall.interfaces."nebula.overlay".allowedTCPPorts = [ guiPort ];
}