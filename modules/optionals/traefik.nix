{ config, options, pkgs, lib, ... }: let
  format = pkgs.formats.yaml {};
  cfg = config.services.traefik;
  mergeDynamicConfigs = cfg.dynamicConfigFile != null && cfg.dynamicConfigOptions != null;

  generatedDynamicConfigFile = format.generate "dynamic.yaml" cfg.dynamicConfigOptions;
  dynamicConfigFile =
    if cfg.dynamicConfigFile == null then
      generatedDynamicConfigFile
    else if cfg.dynamicConfigOptions == null then
      cfg.dynamicConfigFile
    else
      "/run/traefik/dynamic.yaml";

  staticConfigFile =
    if cfg.staticConfigFile == null then
      format.generate "static.yaml" (
        lib.recursiveUpdate cfg.staticConfigOptions {
          providers.file.filename = "${dynamicConfigFile}";
        }
      )
    else
      cfg.staticConfigFile;

  finalStaticConfigFile = if cfg.environmentFiles == [] then staticConfigFile else "/run/traefik/static.yaml";
in {
  config = lib.mkIf mergeDynamicConfigs {
    systemd.services.traefik.serviceConfig = {
      ExecStartPre = lib.mkForce (lib.optional (cfg.environmentFiles != [] || mergeDynamicConfigs) (
        pkgs.writeShellScript "pre-start" ''
          umask 077
          ${lib.optionalString mergeDynamicConfigs ''
            ${pkgs.yq-go}/bin/yq '. *+ load("${cfg.dynamicConfigFile}")' "${generatedDynamicConfigFile}" > ${dynamicConfigFile}
          ''}
          ${lib.optionalString (cfg.environmentFiles != []) ''
            ${pkgs.envsubst}/bin/envsubst -i "${staticConfigFile}" > "${finalStaticConfigFile}"
          ''}
        ''
      ));
      ExecStart = lib.mkForce "${cfg.package}/bin/traefik --configfile=${finalStaticConfigFile}";
    };
  };
}