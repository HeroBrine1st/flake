{ pkgs, flake, lib, config, ... }: {
  environment.systemPackages = with pkgs; [
    nano
    wget
    curl
    jq
    htop
    tree
    ffmpeg
    yt-dlp
    git
    tcpdump
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
    flake.pkgs.bdfr
    compsize
  ] ++ lib.optionals config.boot.isBareMetal [
    hdparm
    smartmontools
    udisks
    usbutils
    lm_sensors
  ] ++ lib.optionals config.virtualisation.docker.enable [
    pkgs.docker-compose
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
}
