{ forgejoURL, config, lib, pkgs, ... }: {
  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=25%" "mode=755" ];
    };
  };

  boot.kernelParams = [ "SYSTEMD_SULOGIN_FORCE=1" ];
  services.getty.autologinUser = "root";

  services.forgejo-runner.instances.main = {
    enable = true;
    runtimes.docker = true;
    assertions = lib.mkForce [ ];
    settings = {
      log.level = "info";
      runner = {
        capacity = 4;
        labels = [
          "docker:docker://node:26-trixie"
          "alpine:docker://alpine"
        ];
      };
      container.network = "host";
    };
  };

  systemd.services.forgejo-runner-main = {
    after = [ "xen-secrets.service" ];
    requires = [ "xen-secrets.service" ];
    serviceConfig.ExecStart = lib.mkForce (pkgs.writeShellScript "forgejo-runner-one-job" ''
      exec ${lib.getExe config.services.forgejo-runner.package} one-job -w \
        --config ${config.services.forgejo-runner.instances.main.configFile} \
        --url ${forgejoURL} \
        --uuid "$(cat /run/xen.secret/forgejo-runner-uuid)" \
        --token-url file:///run/xen.secret/forgejo-runner-token
    '');
  };

  services.impermanence.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;

  security.sudo-rs = {
    enable = true;
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  users.users.herobrine1st = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMx6iwADwNH6wLURS6/jfa7mlKB9wXAPJaN8x61JainS herobrine1st@foxtrot"
    ];
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      AllowUsers = [ "herobrine1st" ];
    };
  };
}