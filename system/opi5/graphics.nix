{ pkgs, lib, ... }: {
  hardware.graphics.enable = true;
  hardware.graphics.package = lib.mkForce pkgs.mesa.drivers;
  environment.systemPackages = [
    pkgs.mesa-demos
  ];

  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "panfrost" ];
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
}
