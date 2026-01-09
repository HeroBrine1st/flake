{ config, options, lib, ... }: let
  cfg = config.services.impermanence;
  startsWith = prefix: string: (builtins.substring 0 (builtins.stringLength prefix) string) == prefix;
  colordHome = "/var/lib/colord";
in {
  options = let
    # HACK: getting options of submodule
    # lib.withSubmodules uses evalModules internally: https://github.com/NixOS/nixpkgs/blob/fe28d2e8e9b5055e84b9edf571a734a677f332ad/lib/types.nix#L1183
    # no reference to result of evalModules is available
    # there is .merge.v2 { loc = [???]; defs = [???]; } which contains valueMeta.configuraton which is a result of extendModules (internally the same evalModules)
    # but valid loc and defs are unknown (also need to pass through some options, see inherit below)
    submoduleOptions = (lib.evalModules {
      modules = options.environment.persistence.type.getSubModules ++ [
        {
          _module.args.name = lib.mkOptionDefault "impermanence submodule definition";
          # top-level submodule options must be passed through
          inherit (config.environment.persistence."${cfg.path}") hideMounts persistentStoragePath;
        }
      ];
    }).options;
  in {
    services.impermanence = {
      enable = lib.options.mkEnableOption "impermanence";
      hideMounts = submoduleOptions.hideMounts;
      path = lib.options.mkOption {
        default = "/nix/persist/system";
        type = lib.types.path;
      };
      extraDirectories = submoduleOptions.directories;
      extraFiles = submoduleOptions.files;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.persistence."${cfg.path}" = {
      hideMounts = cfg.hideMounts;
      directories = lib.mkMerge [
        [
          "/var/log"
          { directory = "/var/tmp"; mode = "0777"; }
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
        ]
        (lib.mkIf config.services.cron.enable [
          "/var/cron"
        ])
        (lib.mkIf config.services.hydra.enable [
          { directory = "/var/lib/hydra"; mode = "750"; user = "hydra"; group = "hydra"; }
        ])
        (let cfgs = config.services.postgresql; in lib.mkIf cfgs.enable [
          { directory = cfgs.dataDir; mode = "750"; user = "postgres"; group = "postgres"; }
        ])
        (let cfgs = config.services.syncthing; in lib.mkIf (cfgs.enable) (
          lib.pipe [ cfgs.dataDir cfgs.configDir ] [
            (builtins.filter (dir: !(startsWith "/home" "${dir}")))
            (builtins.map (dir: { directory = dir; mode = "0700"; inherit (cfgs) user group; }))
          ]
        ))
        (lib.mkIf config.virtualisation.libvirtd.enable [ "/var/lib/libvirt" ]) # owned by root
        (lib.mkIf config.services.llama-cpp.worker.enable [
          { directory = "/var/lib/private/llama-rpc-worker"; mode = "700"; }
        ])
        (lib.mkIf config.services.colord.enable [
          { directory = colordHome; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
        ])
        (lib.mkIf config.networking.networkmanager.enable [
          { directory = "/etc/NetworkManager/system-connections"; mode = "0700"; }
        ])
        (lib.mkIf (config.virtualisation.docker.enable) [
          { directory = "/var/lib/docker"; mode = "0710"; } # owned by root
          "/var/docker_data"
        ])
        (lib.mkIf config.services.traefik.enable [
          { directory = config.services.traefik.dataDir; user = "traefik"; inherit (config.users.users.traefik) group; }
        ])
        (lib.mkIf config.hardware.bluetooth.enable [
          { directory = "/var/lib/bluetooth"; mode = "0700"; }
        ])
        # mkRemovedOptionModule adds an option which triggers its own application!
        (builtins.map (dir: builtins.removeAttrs dir [ "method" ]) cfg.extraDirectories)
      ];
      files = lib.mkMerge [
        [
          "/etc/machine-id"
        ]
        (lib.mkIf config.services.openssh.enable [
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
          "/etc/ssh/ssh_host_rsa_key"
          "/etc/ssh/ssh_host_rsa_key.pub"
        ])
        cfg.extraFiles
      ];
    };

    assertions = lib.mkMerge [
      (lib.optional config.services.colord.enable {
        # evaluation of config.users.users.colord triggers rpcbind module, which eventually triggers filesystems and this module, leading to recursion
        assertion = config.users.users.colord.home == colordHome;
        message = "colord user home changed, now it is ${config.users.users.colord.home}";
      })
    ];
  };
}