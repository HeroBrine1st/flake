{ config, lib, pkgs, stdenvNoCC, fetchFromGitLab, ... }: stdenvNoCC.mkDerivation rec {
  pname = "arc-x-icon-theme";
  version = "v2.1";

  src = fetchFromGitLab {
    # https://gitlab.com/LinxGem33/Arc-X-Icons
    owner = "LinxGem33";
    repo = "Arc-X-Icons";
    rev = version;
    hash = "sha256-f3fFquLccgUfxQ/vyevfQZIU4umVY8kEFTGXJxKhRwA=";
  };

  # These fixup steps are slow and unnecessary
  dontPatchELF = true;
  dontRewriteSymlinks = true;
  dontDropIconThemeCache = true;

  installPhase = ''
    runHook preInstall

    sed -i 's|Name=Arc|Name=Arc-X-D|' "src/Arc-OSX-D/index.theme"
    sed -i 's|Name=Arc|Name=Arc-X-P|' "src/Arc-OSX-P/index.theme"

    mkdir -p $out/share/icons/
    cp --archive --target-directory=$out/share/icons/ src/*

    runHook postInstall
  '';
}