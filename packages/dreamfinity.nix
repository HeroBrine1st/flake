{ stdenvNoCC,
  fetchurl,
  openjdk21,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  bash,
  writeTextFile,
  firejail,
  lib,
  buildFHSEnv,
  javaWithFx ? (openjdk21.override {
    enableJavaFX = true;
  })
}: let

in stdenvNoCC.mkDerivation {
  name = "dreamfinity";
  srcs = [
    (fetchurl {
      url = "https://launcher.dreamfinity.org/Dreamfinity.jar";
      hash = "sha256-Cl4WoGD37puEVTKxo5zubbVPhPIfyqeKLC1mOBkHsFY=";
    })
    (fetchurl {
      url = "https://raw.githubusercontent.com/Noire86/Dreamfinity-Brand-Logo/1cc4b6b487d37cb8c76abfe0187253059fc01a01/gearlogo/SVG/logo.svg";
      hash = "sha256-0XW598OdC2nRa9FEHLKrV6+Cn5PxCpFoF7YE11lSDlk=";
    })
  ];

  dontUnpack = true;

  fhsEnvironment = buildFHSEnv {
    name = "dreamfinity-fhs-env";
    targetPkgs = pkgs: with pkgs; [
      xorg.libXext
      xorg.libX11
      xorg.libXrender
      xorg.libXtst
      xorg.libXi
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXxf86vm

      libGL
      fontconfig

      alsa-lib
    ];
    executableName = "env";
    runScript = "env";
  };

  nativeBuildInputs = [ copyDesktopItems makeWrapper ];

  desktopItems = [
    (makeDesktopItem {
      name = "dreamfinity";
      desktopName = "Dreamfinity";
      icon = "dreamfinity";
      exec = "dreamfinity";
      categories = [ "Game" ];
      terminal = false;
      startupWMClass = "pro.gravit.launcher.dreamFINItYleH";
    })
  ];

  installPhase = ''
    runHook preInstall
    install -d $out/bin/
    read -r -a srcs <<< "$srcs"

    makeWrapper $fhsEnvironment/bin/env $out/bin/dreamfinity \
      --set JAVA_HOME ${javaWithFx} \
      --add-flags "${javaWithFx}/bin/java -jar ''${srcs[0]}"

    install -D -T ''${srcs[1]} $out/share/icons/hicolor/scalable/apps/dreamfinity.svg
    runHook postInstall
  '';

  meta = {
    mainProgram = "dreamfinity";
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
      binaryNativeCode
    ];
  };

  passthru = {
    firejailProfile = writeTextFile {
      name = "dreamfinity.profile";
      text = let
        HOME = "\${HOME}";
        PATH = "\${PATH}";
      in ''
        ignore noexec ${HOME}
        ignore noexec /tmp

        noblacklist ${HOME}/.minecraftlauncher/Dreamfinity
        #include allow-java.inc

        blacklist /sys

        # bwrap
        noblacklist /proc/sys/kernel/overflowuid
        noblacklist /proc/sys/kernel/overflowgid
        seccomp !mount,!pivot_root,!umount2

        include disable-common.inc
        include disable-devel.inc
        include disable-exec.inc
        include disable-interpreters.inc
        include disable-proc.inc
        include disable-programs.inc
        # wrapper requires bash
        # include disable-shell.inc
        include disable-xdg.inc

        mkdir ${HOME}/.minecraftlauncher/Dreamfinity
        whitelist ${HOME}/.minecraftlauncher/Dreamfinity
        include whitelist-common.inc

        apparmor
        caps.drop all
        machine-id
        nodvd
        protocol unix,inet,inet6

        disable-mnt
        private-dev
        private-tmp

        dbus-user none
        dbus-system none

        read-only ${HOME}
        read-write ${HOME}/.minecraftlauncher/Dreamfinity
      '';
    };
  };
}