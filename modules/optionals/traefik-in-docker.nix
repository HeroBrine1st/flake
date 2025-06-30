{ pkgs, modulesPath, lib, config, options, ... }@host: let
  network = "traefik";
  traefikModule = lib.evalModules {
    modules = import (modulesPath + "/module-list.nix") ++ [
      ({ options, ...}: {
        # https://github.com/NixOS/nixpkgs/blob/26d499fc9f1d567283d5d56fcf367edd815dba1d/nixos/modules/virtualisation/nixos-containers.nix#L538-L541
        nixpkgs = if options.nixpkgs ? hostPlatform then
          { inherit (host.pkgs.stdenv) hostPlatform; }
        else
          { localSystem = host.pkgs.stdenv.hostPlatform; };
      })
      {
        services.traefik = lib.recursiveUpdate (builtins.removeAttrs host.config.services.traefik ["docker"]) {
          enable = true;
          staticConfigOptions.providers.docker.network = "${host.config.services.traefik.docker.network}";
        };
        system.stateVersion = host.config.system.stateVersion;
      }
    ];
  };
in {
  options = {
    services.traefik.docker = {
      enable = lib.mkEnableOption "traefik in docker";
      network = lib.mkOption {
        type = lib.types.str;
        default = "traefik";
        description = "Docker network for traefik";
      };
      ports = lib.mkOption {
        type = with lib.types; listOf str;
        default = [];
        description = "Alias to virtualisation.oci-containers.containers.<name>.ports";
      };
      environmentFiles = lib.mkOption {
        type = with lib.types; listOf path;
        default = [ ];
        description = "Alias to virtualisation.oci-containers.containers.<name>.environmentFiles";
      };
    };
  };
  config = lib.mkIf config.services.traefik.docker.enable {
    virtualisation.oci-containers = {
      backend = "docker";
      containers = {
        traefik = assert !config.services.traefik.enable; {
          # do not build image, use /nix/store instead to reuse nixpkgs modules
          image = "almost-scratch";
          imageStream = pkgs.dockerTools.streamLayeredImage {
            name = "almost-scratch";
            tag = "latest";
          };
          volumes = [
            "/nix/store:/nix/store:ro"
            "/var/run/docker.sock:/var/run/docker.sock"
            "${config.services.traefik.dataDir}:${config.services.traefik.dataDir}"
            "/etc/passwd:/etc/passwd/:ro"
            "/etc/group:/etc/group:ro"
          ] ++ builtins.map (x: "${x}:${x}:ro") config.services.traefik.environmentFiles;
          entrypoint = "${pkgs.bash}/bin/bash";
          cmd = let
            su-exec = "${pkgs.su-exec}/bin/su-exec traefik:${config.services.traefik.group}";
          in ["-c" ''
            ${lib.strings.concatStrings (builtins.map (x: "${su-exec} ${x};") traefikModule.config.systemd.services.traefik.serviceConfig.ExecStartPre)}
            exec ${su-exec} ${traefikModule.config.systemd.services.traefik.serviceConfig.ExecStart}
          ''];
          extraOptions = [
            "--network=${network}"
            "--tmpfs=/run/traefik"
          ];
          inherit (config.services.traefik.docker) ports environmentFiles;
        };
      };
    };

    # TODO logrotate

    systemd.services = {
      docker-traefik = {
        after = [ "docker-traefik-network.service" ];
        requires = [ "docker-traefik-network.service" ];
      };
      docker-traefik-network = {
        wantedBy = [ "multi-user.target" ];
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "create-traefik-network" ''
            ${pkgs.docker}/bin/docker network inspect ${network} >/dev/null 2>&1 || \
            ${pkgs.docker}/bin/docker network create ${network}
          '';
        };
      };
    };

    users.users.traefik = {
      group = "traefik";
      home = config.services.traefik.dataDir;
      createHome = true;
      isSystemUser = true;
    };

    users.groups.traefik = {};
  };
}