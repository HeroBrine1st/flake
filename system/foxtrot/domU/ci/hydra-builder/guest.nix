{ ... }: {
  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=25%" "mode=755" ];
    };
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  boot.kernelParams = [ "SYSTEMD_SULOGIN_FORCE=1" ];
  services.getty.autologinUser = "root";

  nix = {
    enable = true;
    gc.automatic = true;
  };

  flake.cache.force = true;
}
