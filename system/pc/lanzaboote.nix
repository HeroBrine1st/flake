{ pkgs, lib, config, ... }: {
  environment.systemPackages = [
    # For debugging and troubleshooting Secure Boot.
    pkgs.sbctl
  ];

  # Lanzaboote currently replaces the systemd-boot module.
  # This setting is usually set to true in configuration.nix
  # generated at installation time. So we force it to false
  # for now.
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";

    autoGenerateKeys.enable = true;
  };

  # pkiBundle path is created by impermanence
  systemd.services.generate-sb-keys.unitConfig.ConditionPathExists = lib.mkForce "!${config.boot.lanzaboote.pkiBundle}/GUID";

  services.impermanence.extraDirectories = [ config.boot.lanzaboote.pkiBundle ];
}
