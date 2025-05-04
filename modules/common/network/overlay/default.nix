{ config, lib, options, pkgs, ... }: let
  hostname = config.networking.hostName;
  ipMap = {
    # /24
    "DESKTOP-IJK2GUG" = "10.168.88.254";
    "alfa" = "10.168.88.72";
    "lynx" = "10.168.88.153";
    "MOBILE-DCV5AQD" = "10.168.88.96";
    "stark-feeling" = "10.168.88.25";
    "bravo" = "10.168.88.57";
    "foxtrot" = "10.168.88.10";
  };
  staticHosts = [
    "alfa"
    "stark-feeling"
    "bravo"
  ];
  servers = staticHosts ++ [ "foxtrot" ];
  isStatic = builtins.elem hostname staticHosts;
  isServer = builtins.elem hostname servers;
  isEnabled = builtins.elem hostname (builtins.attrNames ipMap);
in {
  options.network.overlay = {
    configAppendixFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      description = "Activation-time config file to be merged into build-time config file";
      default = null;
    };
    enabled = lib.mkOption {
      type = lib.types.bool;
      description = "Set to true if overlay network enable condition is true";
      readOnly = true;
    };
  };

  config = {
    network.overlay.enabled = isEnabled;
    services.nebula.networks.overlay = lib.mkIf isEnabled {
      enable = true;

      package = lib.mkIf (config.network.overlay.configAppendixFile != null) (pkgs.callPackage ./wrapper.nix {
        configAppendixFile = config.network.overlay.configAppendixFile;
      });

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
      ] ++ lib.optionals isServer [
        {
          host = "any";
          port = "any";
          proto = "any";
        }
      ];

      # TODO change with impermanence on every host
      ca = "/nix/persist/nebula/ca.crt";
      cert = "/nix/persist/nebula/${hostname}.crt";
      key = "/nix/persist/nebula/${hostname}.key";

      lighthouses = lib.mkIf (!isStatic) (builtins.map (name: ipMap."${name}") staticHosts);
      relays = lib.mkIf (!isStatic) (builtins.map (name: ipMap."${name}") staticHosts);

      isLighthouse = isStatic;
      isRelay = isStatic;
    };
  };
}