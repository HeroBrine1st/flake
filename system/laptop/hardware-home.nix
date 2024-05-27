{ home-manager, ... }: {
  home-manager.users.herobrine1st = {
    xdg.configFile = {
      "gtk-3.0/bookmarks".text = ''
        file:///home/herobrine1st/Desktop
        file:///home/herobrine1st/Git
        file:///home/herobrine1st/Videos/OBS
        file:///.fsroot File System Root
        file:///tmp
        file:///mnt/tmp /mnt/tmp
        file:///mnt/extra Extra
        file:///mnt/hdd HDD
        file:///home/herobrine1st/Documents
        file:///home/herobrine1st/Music
        file:///home/herobrine1st/Pictures
        file:///home/herobrine1st/Videos
        file:///home/herobrine1st/Downloads
        sftp://d.herobrine1st.ru/mnt/basic Seagate Basic on Orange Pi 5
      '';
    };
  };
}