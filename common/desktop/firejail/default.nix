{ config, lib, pkgs, custom-pkgs, ... }: {
  environment.etc = {
    "firejail/globals.local".text = ''
      blacklist /.fsroot
    '';
    "firejail/lutris.local".text = ''
      ignore restrict-namespaces

      ignore mkdir ''${HOME}/Games
      ignore whitelist ''${HOME}/Games
      ignore whitelist ''${DOWNLOADS}
      #ignore mkdir ''${HOME}/.cache/lutris
      #ignore mkdir ''${HOME}/.cache/wine
      #ignore mkdir ''${HOME}/.cache/winetricks
      ignore mkdir ''${HOME}/.cache

      blacklist ''${DOWNLOADS}

      noblacklist ''${HOME}/.config/MangoHud
      whitelist ''${HOME}/.config/MangoHud
      whitelist /mnt/extra/Lutris
      whitelist ''${HOME}/.cache/lutris
      whitelist ''${HOME}/.cache/wine
      whitelist ''${HOME}/.cache/winetricks

      ignore seccomp !modify_ldt
      ignore seccomp.32 !modify_ldt

      apparmor

      deterministic-shutdown

      join-or-start lutris
    '';
    "firejail/nodejs-common.local".text = ''
      mkdir ''${HOME}/.node-gyp
      mkdir ''${HOME}/.npm
      mkdir ''${HOME}/.npm-packages
      mkfile ''${HOME}/.npmrc
      mkdir ''${HOME}/.nvm
      mkdir ''${HOME}/.yarn
      mkdir ''${HOME}/.yarn-config
      mkdir ''${HOME}/.yarncache
      mkfile ''${HOME}/.yarnrc
      whitelist ''${HOME}/.node-gyp
      whitelist ''${HOME}/.npm
      whitelist ''${HOME}/.npm-packages
      whitelist ''${HOME}/.npmrc
      whitelist ''${HOME}/.nvm
      whitelist ''${HOME}/.yarn
      whitelist ''${HOME}/.yarn-config
      whitelist ''${HOME}/.yarncache
      whitelist ''${HOME}/.yarnrc
      whitelist ''${HOME}/Git
      include whitelist-common.inc
    '';
    "firejail/spotify.local".text = ''
      join-or-start spotify
      whitelist ''${HOME}/Music/Main
    '';
    "firejail/steam.local".text = ''
      ignore private-etc
      ignore restrict-namespaces
      ignore seccomp

      # Gamepad
      ignore private-dev
      ignore nou2f
      ignore noroot

      # Generic configuration
      noblacklist ''${HOME}/.cache
      noblacklist /mnt/games/Steam
      noblacklist /mnt/games_hdd/Steam
      noblacklist /mnt/games_ssd/Steam
      whitelist ''${HOME}/.cache
      whitelist /mnt/games/Steam
      whitelist /mnt/extra/Steam

      caps.keep sys_nice
      join-or-start steam

      # Factorio
      noblacklist ''${HOME}/.factorio
      whitelist ''${HOME}/.factorio

      # Elite: Dangerous
      env DOTNET_BUNDLE_EXTRACT_BASE_DIR=/mnt/extra/Steam/.dotnet_bundle_extract
      whitelist ''${HOME}/.config/min-ed-launcher
    '';
  };

  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      lutris = {
        executable = "${pkgs.lutris}/bin/lutris";
        profile = "${pkgs.firejail}/etc/firejail/lutris.profile";
      };
      node = {
        executable = "${pkgs.nodejs}/bin/node";
        profile = "${pkgs.firejail}/etc/firejail/node.profile";
      };
      spotify = {
        executable = "${custom-pkgs.spotify}/bin/spotify";
        profile = "${pkgs.firejail}/etc/firejail/spotify.profile";
      };
      steam = {
        executable = "${pkgs.steam}/bin/steam";
        profile = "${pkgs.firejail}/etc/firejail/steam.profile";
      };
      steam-runtime = {
        executable = "${pkgs.steam}/bin/steam-runtime";
        profile = "${pkgs.firejail}/etc/firejail/steam.profile";
      };
      vesktop = {
        executable = "${custom-pkgs.vesktop}/bin/vesktop";
        profile = "${./vesktop.profile}";
      };
      tlauncher = {
        executable = "${custom-pkgs.tlauncher}/bin/tlauncher";
        profile = "${./tlauncher.profile}";
      };
    };
  };
}
