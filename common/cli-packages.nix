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
    mangohud
    gamescope
    gamemode
    sing-box
    sing-geosite
    sing-geoip
    nodejs
    jetbrains-mono
    unzip
    file
    pv
  ];

  programs.nano.nanorc = ''
    set tabsize 4
    set tabstospaces
  '';
}