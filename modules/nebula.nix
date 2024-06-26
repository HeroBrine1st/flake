{ config, lib, ... }: let
  hostname = config.networking.hostName;
  ipMap = {
    # /24
    "DESKTOP-IJK2GUG" = "10.168.88.254";
    "opi5" = "10.168.88.72";
    "lynx" = "10.168.88.153";
  };
  staticHosts = {
    "10.168.88.72" = ["109.106.137.208:4242"]; # opi5
  };
  isStatic = builtins.hasAttr (ipMap."${hostname}") staticHosts;
in {
  services.nebula.networks.overlay = {
    enable = true;
    firewall.outbound = [
      {
        host = "any";
        port = "any";
        proto = "any";
      }
    ];
    firewall.inbound = [
      {
        host = "any";
        port = "any";
        proto = "icmp";
      }
    ];

    # TODO change with impermanence on every host
    ca = "/nix/persist/nebula/ca.crt";
    cert = "/nix/persist/nebula/${hostname}.crt";
    key = "/nix/persist/nebula/${hostname}.key";

    # remove current machine from list
    staticHostMap = builtins.removeAttrs staticHosts [ ipMap."${hostname}" ];
    lighthouses = lib.mkIf (!isStatic) (builtins.attrNames staticHosts);
    relays = lib.mkIf (!isStatic) (builtins.attrNames staticHosts);

    isLighthouse = isStatic;
    isRelay = isStatic;
  };
}