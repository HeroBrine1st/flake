{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  stdenvNoCC,
  bun,
  makeWrapper,
  typescript,
  nodejs,
  imagemagick
}: let
  version = "0.16.13";
  src = fetchFromGitHub {
    owner = "letta-ai";
    repo = "letta-code";
    tag = "v${version}";
    hash = "sha256-njOP/nhzt9KqypbTCLuhgeDnV+LM7e/kbnX1Tt6TrU4=";
  };
  node_modules = stdenvNoCC.mkDerivation {
    name = "letta-code-node_modules";
    impureEnvVars = lib.fetchers.proxyImpureEnvVars
      ++ [ "GIT_PROXY_COMMAND" "SOCKS_SERVER" ];
    inherit src;
    nativeBuildInputs = [ bun ];
    dontConfigure = true;
    buildPhase = ''
      bun install --no-progress --frozen-lockfile
    '';
    installPhase = ''
      mkdir -p $out/node_modules

      rm ./node_modules/.cache -rf
      cp -R ./node_modules $out
    '';
    dontFixup = true;
    outputHash = "sha256-RhaYNDWUdfML8wSOZ/iQwJ1AUWOU8BC9vkMOy9nPVaY="; # lib.fakeHash;
    outputHashMode = "recursive";
  };
in stdenvNoCC.mkDerivation {
  pname = "letta-code";
  inherit version src;
  nativeBuildInputs = [ makeWrapper typescript imagemagick bun typescript ];

  configurePhase = ''
    runHook preConfigure

    cp -R ${node_modules}/node_modules .
    chmod -R +w ./node_modules

    runHook postConfigure
  '';

  patches = [
    ./use-tsc-from-path.patch
    # I have questions to https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD
    # Build recipe is copied verbatim, but this patch is required for it to launch
    ./no-external-modules.patch
  ];

  buildPhase = ''
    runHook preBuild

    USE_MAGICK=1 bun run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/letta-code
    cp -R ./letta.js $out/share/letta-code/letta.js

    # bun run tries to resolve something even given no external modules
    # same question to PKGBUILD, idk how they avoid that
    # Anyway letta-code is for node too, so should be okay
    makeWrapper ${nodejs}/bin/node $out/bin/letta-code \
      --add-flags "$out/share/letta-code/letta.js"

    runHook postInstall
  '';
}