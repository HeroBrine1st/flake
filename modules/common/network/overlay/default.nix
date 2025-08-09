{ config, lib, options, pkgs, systems, ... }: let
  hostname = config.networking.hostName;
  staticHosts = map (e: e.networks.overlay.address) (builtins.attrValues (lib.attrsets.filterAttrs (k: v: v.isStatic && v.networks ? overlay && k != hostname) systems));
  isStatic = systems."${hostname}".isStatic;
  isServer = systems."${hostname}".isServer;
  isEnabled = systems."${hostname}".networks ? overlay;
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
          group = "entryhost"; # entrypoint + host = entryhost
        }
      ];

      # TODO change with impermanence on every host
      ca = "/nix/persist/nebula/ca.crt";
      cert = "/nix/persist/nebula/${hostname}.crt";
      key = "/nix/persist/nebula/${hostname}.key";

      lighthouses = lib.mkIf (!isStatic) staticHosts;
      relays = lib.mkIf (!isStatic) staticHosts;

      isLighthouse = isStatic;
      isRelay = isStatic;

      settings = {
        pki.blocklist = [
          "c62d955157786559bfb2f468f14b10c8e17cbbf232b6d2d2fa3be8ee8b4b8b89"
        ];
      };
    };
  };
}