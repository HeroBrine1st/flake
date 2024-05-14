{ vesktop, makeDesktopItem }: vesktop.overrideAttrs (old: {
  # https://www.reddit.com/r/discordapp/comments/k6s89b/i_recreated_the_discord_loading_animation/
  postPatch = (old.postPatch or "") + ''
    cp --remove-destination ${./discord.gif} static/shiggy.gif
  '';

  postInstall = (old.postInstall or "") + ''
    cp ${./discord.png} $out/share/icons/hicolor/256x256/apps/discord.png
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "vesktop";
      desktopName = "Vesktop";
      exec = "vesktop %U";
      icon = "discord";
      startupWMClass = "Vesktop";
      genericName = "Internet Messenger";
      keywords = [ "discord" "vencord" "electron" "chat" ];
      categories = [ "Network" "InstantMessaging" "Chat" ];
    })
  ];
})