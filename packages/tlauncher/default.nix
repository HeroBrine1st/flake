{ lib, stdenv, openjdk8, buildFHSUserEnv, fetchzip, fetchurl, copyDesktopItems, makeDesktopItem }: let
  version = "1.0";
  src = fetchurl {
    name = "tlauncher.jar";
    url = "https://llaun.ch/jar";
    sha256 = "sha256-3y0lFukFzch6aOxFb4gWZKWxWLqBCTQlHXtwp0BnlYg=";
  };
  fhs = buildFHSUserEnv {
    name = "tlauncher";
    runScript = ''
      ${openjdk8}/bin/java -jar "${src}" "$@"
    '';
    targetPkgs = pkgs: with pkgs; [
      alsa-lib
      cpio
      cups
      file
      fontconfig
      freetype
      giflib
      glib
      gnome2.GConf
      gnome2.gnome_vfs
      gtk2
      libjpeg
      libGL
      openjdk8-bootstrap
      perl
      which
      xorg.libICE
      xorg.libX11
      xorg.libXcursor
      xorg.libXext
      xorg.libXi
      xorg.libXinerama
      xorg.libXrandr
      xorg.xrandr
      xorg.libXrender
      xorg.libXt
      xorg.libXtst
      xorg.libXtst
      xorg.libXxf86vm
      zip
      zlib
    ];
  };
  desktopItem = makeDesktopItem {
    name = "tlauncher";
    exec = "tlauncher";
    icon = ./icon-256.png;
    comment = "Minecraft launcher";
    desktopName = "TLauncher";
    categories = [ "Game" ];
    startupWMClass = "ru-turikhay-tlauncher-bootstrap-Bootstrap";
  };
in stdenv.mkDerivation {
  pname = "tlauncher-wrapper";
  inherit version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir $out/{bin,share/applications} -p
    install ${fhs}/bin/tlauncher $out/bin
    runHook postInstall
  '';

  nativeBuildInputs = [ copyDesktopItems ];
  desktopItems = [ desktopItem ];
}