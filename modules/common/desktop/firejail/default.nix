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
      deterministic-shutdown
      join-or-start steam

      # Factorio
      mkdir ''${HOME}/.factorio
      noblacklist ''${HOME}/.factorio
      whitelist ''${HOME}/.factorio

      # Elite: Dangerous
      env DOTNET_BUNDLE_EXTRACT_BASE_DIR=/mnt/extra/Steam/.dotnet_bundle_extract
      whitelist ''${HOME}/.config/min-ed-launcher
    '';
    "firejail/whitelist-run-common.local".text = ''
      # /nix/store is anyway world-readable
      whitelist /run/current-system
      # SUID binaries are in /run/wrappers
    '';
    "firejail/firefox-common.local".text = ''
      # Unite extension
      noblacklist ''${HOME}/.config/gtk-4.0
      whitelist ''${HOME}/.config/gtk-4.0
      # Add the next line to firefox-common.local to enable native notifications.
      dbus-user.talk org.freedesktop.Notifications
      # Add the next line to firefox-common.local to allow inhibiting screensavers.
      dbus-user.talk org.freedesktop.ScreenSaver
      # Add the next line to firefox-common.local to allow screensharing under
      # Wayland.
      dbus-user.talk org.freedesktop.portal.Desktop
      # Also add the next line to firefox-common.local if screensharing does not work
      # with the above lines (depends on the portal implementation).
      #ignore noroot

      ignore disable-mnt
      # TODO not a mountpoint, needs to be moved somewhere
      blacklist /mnt/secure

      ignore private-tmp
    '';
    "firejail/firefox.local".text = ''
      # --name=firefox (the default) is entirely ignored
      join-or-start firefox
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
      steam = {
        executable = "${config.programs.steam.package}/bin/steam";
        profile = pkgs.runCommand "steam.profile" {} ''
          patch "${pkgs.firejail}/etc/firejail/steam.profile" "${./steam.profile.patch}" -o - > "$out"
        '';
      };
      steam-runtime = {
        executable = "${config.programs.steam.package}/bin/steam-runtime";
        profile = "${pkgs.firejail}/etc/firejail/steam.profile";
      };
      tlauncher = {
        executable = "${custom-pkgs.tlauncher}/bin/tlauncher";
        profile = "${./tlauncher.profile}";
      };
      android-studio = {
        executable = "${pkgs.android-studio}/bin/android-studio";
        profile = "${./android-studio.profile}";
      };
      firefox = let
        # it is the dirtiest code of my life
        # but it works yay
        # find the package that firefox module has added to environment.systemPackages
        matching = builtins.filter (p: p.name == config.programs.firefox.package.name) config.environment.systemPackages;
        # ensure it is only one package
        finalPackage = assert (builtins.length matching == 1); builtins.head matching;
      in {
        executable = "${finalPackage}/bin/firefox";
        profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
      };
    };
  };
}
