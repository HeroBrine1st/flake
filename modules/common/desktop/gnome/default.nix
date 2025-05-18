{ pkgs, ... }: {
  imports = [
    ./dconf
  ];

  services.xserver.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.gnome.core-apps.enable = false;
  environment.gnome.excludePackages = [ pkgs.gnome-tour ];
  services.xserver.excludePackages = [ pkgs.xterm ];

  # Extensions
  environment.systemPackages = with pkgs; [
    # removed, gnomeExtensions.lockscreen-extension is a replacement but is not available on gnome 48
    # https://github.com/PRATAP-KUMAR/gse-lockscreen-extension
    #gnomeExtensions.control-blur-effect-on-lock-screen
    gnomeExtensions.panel-corners
    gnomeExtensions.primary-input-on-lockscreen
    gnomeExtensions.quick-settings-tweaker
    #gnomeExtensions.removable-drive-menu # somehow already available
    gnomeExtensions.system-monitor-next
    gnomeExtensions.dash-to-dock
    gnomeExtensions.unite xorg.xprop
    gnomeExtensions.gsconnect
    gnomeExtensions.clipboard-indicator
  ];

  # gsconnect
  environment.sessionVariables = rec {
    NAUTILUS_4_EXTENSION_DIR = "/run/current-system/sw/lib/nautilus/extensions-4/";
  };

  fonts.packages = with pkgs; [
    cantarell-fonts
  ];

  networking.firewall = {
    allowedTCPPortRanges = [
      { from = 1714; to = 1764; } # KDE Connect
    ];
    allowedUDPPortRanges = [
      { from = 1714; to = 1764; } # KDE Connect
    ];
  };
}