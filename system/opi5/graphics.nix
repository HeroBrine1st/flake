{ pkgs, lib, ... }: {
  hardware.opengl.enable = true;
  hardware.opengl.package = lib.mkForce pkgs.mesa;
  environment.systemPackages = [
    pkgs.mesa-demos
  ];

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
}
