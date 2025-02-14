{ config, lib, pkgs, stdenvNoCC, fetchFromGitLab, ... }: let
  paper-icon-theme = pkgs.callPackage ./paper-icon-theme.nix {};
in stdenvNoCC.mkDerivation rec {
  pname = "arc-x-icon-theme";
  version = "v2.1";

  src = fetchFromGitLab {
    owner = "LinxGem33";
    repo = "Arc-X-Icons";
    rev = version;
    hash = "sha256-f3fFquLccgUfxQ/vyevfQZIU4umVY8kEFTGXJxKhRwA=";
  };

  patchPhase = ''
    rm -rf ./src/Paper*

    sed -i 's|Name=Arc|Name=Arc-X-D|' "./src/Arc-OSX-D/index.theme"
    sed -i 's|Name=Arc|Name=Arc-X-P|' "./src/Arc-OSX-P/index.theme"

    rm -rf ./src/Arc-OSX-*/mimetypes/*/application-x-keepass2.svg
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons/
    ln -s ${paper-icon-theme}/share/icons/Paper $out/share/icons/
    ln -s ${paper-icon-theme}/share/icons/Paper-Mono-Dark $out/share/icons/
    cp --archive --target-directory=$out/share/icons/ src/*

    runHook postInstall
  '';
}
