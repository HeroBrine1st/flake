{ systems, config, ... }: let
  guiPort = 8384;
in {
  services.syncthing = {
    user = "syncthing";
    configDir = "/var/lib/syncthing/config";
    dataDir = "/var/lib/syncthing/folders";
    overrideFolders = true;
    guiAddress = "${systems."${config.networking.hostName}".networks.overlay.address}:${builtins.toString guiPort}";
  };

  networking.firewall.interfaces."nebula.overlay".allowedTCPPorts = [ guiPort ];
}