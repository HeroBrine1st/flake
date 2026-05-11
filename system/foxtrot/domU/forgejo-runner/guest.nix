{ pkgs, config, ... }: {
  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=25%" "mode=755" ];
    };
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers."forgejo-runner" = {
      autoStart = true;
      image = "data.forgejo.org/forgejo/runner:${pkgs.forgejo-runner.version}";
      volumes = [
        "/nix/persist/runner.yml:/config.yml:ro"
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];
      user = "0:${toString config.users.groups.docker.gid}";
      cmd = [ "forgejo-runner" "daemon" "--config=/config.yml" ];
    };
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