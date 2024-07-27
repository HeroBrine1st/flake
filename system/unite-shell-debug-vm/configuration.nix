{ config, lib, pkgs, custom-pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.tmp.useTmpfs = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nix = {
    settings = {
      experimental-features = [ "flakes" "nix-command" ];
      auto-optimise-store = true;
    };
  };

  # security.sudo.wheelNeedsPassword = false;

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.xserver.videoDrivers = [ "qxl" ];

  services.spice-vdagentd.enable = true;
  virtualisation.qemu.options = [
    "-vga qxl"
  ];
  virtualisation.memorySize = 4096;
  virtualisation.cores = 2;

  services.gnome.core-utilities.enable = false;
  environment.gnome.excludePackages = [ pkgs.gnome-tour ];
  services.xserver.excludePackages = [ pkgs.xterm ];
  documentation.nixos.enable = false;

  # Set your time zone.
  time.timeZone = "Europe/London";

  i18n = {
    defaultLocale = "en_GB.UTF-8";
  };

  environment.systemPackages = with pkgs; [
    gnomeExtensions.unite xorg.xprop
    gnomeExtensions.dash-to-dock # otherwise it's impossible to launch apps

    custom-pkgs.vesktop

    pkgs.xorg.xf86videoqxl

    gnome-terminal
  ];


  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.pulseaudio.enable = false;

  environment.sessionVariables = rec {
    NAUTILUS_4_EXTENSION_DIR = "/run/current-system/sw/lib/nautilus/extensions-4/";
  };

  system.stateVersion = "23.11"; # Do not change

  home-manager.users.herobrine1st = {
    home.stateVersion = "23.11";
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        enable-hot-corners = true;
      };

      "org/gnome/mutter" = {
        edge-tiling = true;
      };

      "org/gnome/shell/extensions/unite" = {
        autofocus-windows = false;
        extend-left-box = false;
        greyscale-tray-icons = false;
        hide-app-menu-icon = false;
        hide-window-titlebars = "maximized";
        notifications-position = "center";
        show-appmenu-button = true;
        show-legacy-tray = true;
        use-activities-text = false;
        window-buttons-placement = "right";
      };

      "org/gnome/shell/extensions/dash-to-dock" = {
        apply-custom-theme = false;
        background-opacity = 0.8;
        click-action = "focus-or-previews";
        dash-max-icon-size = 64;
        dock-position = "BOTTOM";
        height-fraction = 0.9;
        hotkeys-overlay = false;
        hotkeys-show-dock = false;
        icon-size-fixed = false;
        intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
        show-mounts = false;
        show-trash = false;
        show-icons-emblems = false;
        show-dock-urgent-notify = false;
        running-indicator-style = "DOTS";
      };

      "org/gnome/shell" = {
        enabled-extensions = [
          # IDK what are those, was enabled by default on arch
          "volume-mixer@evermiss.net"
          "tweaks-system-menu@extensions.gnome-shell.fifi.org"
          "sound-output-device-chooser@kgshank.net"
          "ding@rastersoft.com"
          "gnomebedtime@ionutbortis.gmail.com"

          # External
          "unite@hardpixel.eu"
          "dash-to-dock@micxgx.gmail.com"
        ];
      };
    };
  };

  users.users.herobrine1st = {
    isNormalUser = true;
    description = "HeroBrine1st Erquilenne";
    extraGroups = [ "wheel" "docker" "libvirtd" "wireshark" "adbusers" "dialout" ];
    password = "p4$$w0rd";
  };
}
