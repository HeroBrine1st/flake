{ lib, config, ... }: {
  environment.shellAliases = {
    ytmusic = "yt-dlp -f bestaudio --extract-audio -o '%(playlist_index)s. %(title)s.%(ext)s'";
    ytvideo = "yt-dlp --write-sub --sub-lang ru,en.* --sponsorblock-mark all --embed-metadata --merge-output-format mkv";
    xclip = "xclip -selection c";
    killall = "killall -I";
    # TODO remove when sudo-rs is replaced with run0 on servers too
    sudo = lib.mkIf (config.security.sudo.enable == false && config.security.sudo-rs.enable == false) "run0";
  };
}