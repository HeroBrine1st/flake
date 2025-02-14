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
    
    speedtest-cli
    pwgen
    dig
    custom-pkgs.bdfr
  ];

  environment.python = {
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
}
