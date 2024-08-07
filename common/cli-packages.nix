{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    nano
    wget
    curl
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
    (python3.withPackages(pythonPkgs: with pythonPkgs; [
      rich
      ptpython
      evdev
    ]))
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
  ];

  programs.nano.nanorc = ''
    set tabsize 4
    set tabstospaces
  '';
}
