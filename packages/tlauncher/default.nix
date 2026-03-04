{ lib, stdenv, openjdk8, buildFHSEnv, fetchzip, fetchurl, copyDesktopItems, makeDesktopItem }: let
  version = "1.0";
  src = fetchurl {
    name = "tlauncher.jar";
    url = "https://llaun.ch/jar";
    sha256 = "sha256-3y0lFukFzch6aOxFb4gWZKWxWLqBCTQlHXtwp0BnlYg=";
  };
  fhs = buildFHSEnv {
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
      #gnome2.GConf  # broken due to 2to3 removal
      gtk2
      libjpeg
      libGL
      openjdk8-bootstrap
      perl
      which
      libice
      libx11
      libxcursor
      libxext
      libxi
      libxinerama
      libxrandr
      xrandr
      libxrender
      libxt
      libxtst
      libxxf86vm
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