{ config, lib, pkgs, custom-pkgs, ... }: {
  environment.etc = {
    "firejail/globals.local".text = ''
      blacklist /.fsroot
      blacklist ''${RUNUSER}/docker.sock
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
      noblacklist /mnt/extra/Steam
      noblacklist ''${HOME}/.config/gamescope
      whitelist ''${HOME}/.cache
      whitelist /mnt/extra/Steam
      whitelist ''${HOME}/.config/gamescope

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

      ignore private-tmp
    '';
    "firejail/firefox.local".text = ''
      name firefox
    '';
    # https://github.com/netblue30/firejail/blob/master/etc/firejail.config
    "firejail/firejail.config".text = ''
      # Force use of nonewprivs.  This mitigates the possibility of
      # a user abusing firejail's features to trick a privileged (suid
      # or file capabilities) process into loading code or configuration
      # that is partially under their control.  Default disabled
      force-nonewprivs yes
    '';
  };

  # TODO wrap in environment.systemPackages because lib.getExe is unsafe
  # TODO use nixpak or bubblejail (anything bwrap-based because firejail disallows bind mounts)
  programs.firejail = let
    # environemnt is interpreted literally and allows interpolation!
    sandboxJetbrains = { package, prefix ? null, environment ? {} }: let
      exe = lib.getExe package;
      # SAFETY: the resulting string is not a path
      name = builtins.unsafeDiscardStringContext (builtins.baseNameOf exe);
      executable = let
        sortedKeys = builtins.sort builtins.lessThan (builtins.attrNames environment);
      in if prefix == null then exe else pkgs.writeShellScript "${name}-wrapped" ''
        ${lib.strings.concatMapStringsSep "\n" (key: ''export ${key}="${environment."${key}"}"'') sortedKeys}
        exec ${lib.escapeShellArgs (prefix ++ [ exe ])}
      '';
    in assert builtins.elem package config.environment.systemPackages; {
      "${name}" = {
        executable = executable;
        profile = "${pkgs.callPackage ./jetbrains-profile.nix { ideName = name; }}";
      };
    };
  in {
    enable = true;
    wrappedBinaries = lib.mkMerge [
      {
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
            patch "${pkgs.firejail}/etc/firejail/steam.profile" "${./steam.profile.patch}" -o "$out"
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
        dreamfinity = {
          executable = "${custom-pkgs.dreamfinity}/bin/dreamfinity";
          profile = custom-pkgs.dreamfinity.firejailProfile;
        };
      }
      (sandboxJetbrains { 
        package = pkgs.android-studio; 
        environment = { GRADLE_USER_HOME = "$HOME/.cache/Gradle"; };
        prefix = [ "env" ];
      })
      (sandboxJetbrains { package = custom-pkgs.jetbrains.idea-ultimate; })
      (sandboxJetbrains {
        package = pkgs.jetbrains.pycharm-community-bin;
        prefix = let
          env = pkgs.buildFHSEnv {
            name = "pycharm-fhs-env";
            targetPkgs = pkgs: (with pkgs;
              [
                libz # llama-index, numpy, or something, idk
                xorg.libXcursor # Xwayland cursor
             ]);
            runScript = "env";
          };
        in [
          "${env}/bin/pycharm-fhs-env"
          "PIPENV_VENV_IN_PROJECT=1"
          # "PIPENV_CUSTOM_VENV_NAME=venv" does not work with venv in project
        ];
      })
      (sandboxJetbrains { package = pkgs.jetbrains.webstorm; })
      (sandboxJetbrains { package = custom-pkgs.jetbrains.clion; })
      (sandboxJetbrains { package = pkgs.jetbrains.rust-rover; })
      (sandboxJetbrains {
        package = pkgs.jetbrains.idea-community-bin;
        environment = { GRADLE_USER_HOME = "$HOME/.cache/Gradle"; };
        prefix = let
          isUnfree = licenses: lib.lists.any (l: !l.free or true) licenses;
          env = pkgs.buildFHSEnv {
            name = "idea-fhs-env";
            # There's only two cases
            # Either you are a nixpkgs maintainger, or that's something you've never seen
            # MORE THAN ONE HUNDRED LIBRARIES! And all of that for android!
            targetPkgs = pkgs: (with pkgs; ([
              libGL
              libz
              xorg.libX11 # required by android plugin on wayland. By android plugin itself, not by AVD.
              # AVD, and this all can be replaced by building android sdk with nix
              # looking at the fact they use patchelf without buildInputs (from where I tried to copy this list) makes me doubt AVD will work with nix SDK..
              libpulseaudio
              libpng
              nss
              nspr
              expat
              libdrm
              util-linux.lib # that's libuuid! Try guess it!
              libbsd
            ] ++ (lib.pipe pkgs.xorg [ # ALL xorg libraries! AVD is insatiable! Probably not all of them are needed but that's 96 paths 23.25 MiB in total
              builtins.attrValues
              (builtins.filter lib.attrsets.isDerivation) # some are functions
              (builtins.filter (pkg: # free
                if pkg.meta ? "licenses" then !(isUnfree pkg.meta.licenses)
                else if pkg.meta ? "license" then !(isUnfree [ pkg.meta.license ])
                else true
              ))
              (builtins.filter (pkg: !(pkg.meta ? "broken") || pkg.meta.broken == false)) # non-broken
              (builtins.filter (pkg: !(pkg.meta ? "platforms") # supported by platform
                || builtins.length pkg.meta.platforms == 0
                || builtins.elem pkgs.stdenv.hostPlatform.system pkg.meta.platforms))
              (builtins.filter (pkg: (builtins.substring 0 4 pkg.name) != "xf86")) # not drivers
            ])));
            runScript = "env";
          };
        in [
          "${env}/bin/idea-fhs-env"
          "LD_LIBRARY_PATH=${pkgs.libGL}/lib"
        ];
      })
    ];
  };
}
