{ pkgs, custom-pkgs, lib, config, ... }: {
  environment.systemPackages = with pkgs; [
    nano
    wget
    curlHTTP3
    hdparm
    smartmontools
    htop
    udisks
    tree
    ffmpeg
    yt-dlp
    usbutils
    git
    tcpdump
    lm_sensors
    psmisc
    gnupg age
    gnumake
    sing-box
    unzip
    file
    pv
    yq-go

    pwgen
    dig
    custom-pkgs.bdfr
  ] ++ lib.optionals config.virtualisation.docker.enable [ pkgs.docker-compose ];

  programs.python = {
    enable = true;
    modules = pythonPkgs: with pythonPkgs; [
      rich
      ptpython
      evdev
      requests
    ];
  };

  programs.nano.nanorc = ''
    set tabsize 4
    set tabstospaces
  '';

  security.sudo.enable = false;
}
