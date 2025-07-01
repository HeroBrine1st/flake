{ pkgs, custom-pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    nano
    wget
    curlHTTP3
    hdparm
    smartmontools
    docker-compose
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
    gnupg
    gnumake
    sing-box
    sing-geosite
    sing-geoip
    unzip
    file
    pv
    yq-go
    
    speedtest-cli
    pwgen
    dig
    custom-pkgs.bdfr
  ];

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
  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
  };
}
