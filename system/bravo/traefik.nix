{ pkgs, modulesPath, lib, config, ... }@host: let
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
        services.traefik = {
          enable = true;
          staticConfigOptions.entryPoints.web.address = ":80";
        };
        system.stateVersion = host.config.system.stateVersion;
      }
    ];
  };
in {
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      traefik = {
        # do not build image, use /nix/store instead to reuse nixpkgs modules
        image = "stratch";
        volumes = [
          "/nix/store:/nix/store:ro"
          #"/var/run/docker.sock:/var/run/docker.sock"
          #"/var/log/traefik/:/var/log/traefik/"
        ];
        entrypoint = "${pkgs.bash}/bin/bash";
        cmd = ["-c" "exec ${traefikModule.config.systemd.services.traefik.serviceConfig.ExecStart}"];
        extraOptions = [
          "--network=${network}"
        ];
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
        ExecStart = ''
          ${pkgs.docker}/bin/docker network inspect ${network} >/dev/null 2>&1 || \
          ${pkgs.docker}/bin/docker network create ${network}
        '';
      };
    };
  };

}