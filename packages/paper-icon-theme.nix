{ config, lib, pkgs, stdenvNoCC, fetchFromGitHub, meson, ninja, python3, ... }: stdenvNoCC.mkDerivation rec {
  pname = "paper-icon-theme";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "snwh";
    repo = pname;
    rev = "v.${version}";
    hash = "sha256-lIiUp3scWj5n7gvkT548PC6l5mz51gsp/JEGgbvFl8w=";
  };

  patchPhase = ''
    # GNOME Disk Utility no longer uses gnome-disks icon
    for file in Paper/*/apps/disk-utility.png; do
      echo -n "Symlinking "
      ln -vs disk-utility.png "$(dirname "$file")/org.gnome.DiskUtility.png"
    done
    # Same for terminal
    for file in Paper/*/apps/terminal.png; do
      echo -n "Symlinking "
      ln -vs terminal.png "$(dirname "$file")/org.gnome.Terminal.png"
    done
    # LibreOffice is patched to use icons without "libreoffice" for whatever reason
    for file in Paper/*/apps/libreoffice-{base,calc,chart,draw,impress,main,math,startcenter,writer}.*; do
      base="$(basename $file)"
      echo -n "Symlinking "
      ln -vsf "$base" "''${file/libreoffice-/}"
    done
    # Also I like default icons on my IDEs
    rm -v Paper/*/apps/{intellij,pycharm,android-std,android-studio}*
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons/
    cp --archive --target-directory=$out/share/icons/ Paper Paper-Mono-Dark

    runHook postInstall
  '';
}