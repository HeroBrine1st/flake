{ pkgs-unstable, pkgs-stable, fenix, ags, pkgs-bdfr, system, ... }@inputs: let
  lib = pkgs.lib;
  pkgs = pkgs-unstable.legacyPackages."${system}";
  pkgs-jetbrains-oss = inputs.pkgs-jetbrains-oss.legacyPackages."${system}";
  pkgsNamed = names: pkg: builtins.elem (lib.getName pkg) names;
  pkgs-cuda = import pkgs-unstable {
    inherit system;
    config.allowUnfreePredicate = pkgsNamed [ "cuda_cccl" "cuda_cudart" "libcublas" "cuda_nvcc" ];
  };
  pkgs-krita = import inputs.pkgs-krita { inherit system; };
  all-pkgs = pkgs // flake-pkgs // { pkgs = all-pkgs; };
  callPackage = lib.customisation.callPackageWith all-pkgs;
  callPackages = lib.customisation.callPackagesWith all-pkgs;
  flake-pkgs = {
    inherit callPackage callPackages;
    fenix = (import pkgs-unstable { inherit system; overlays = [ fenix.overlays.default ]; }).fenix;
    topbar = import ./topbar { inherit pkgs ags; };

    bdfr = pkgs-bdfr.legacyPackages."${system}".callPackage ./bdfr {};
    debounce-keyboard = callPackage ./debounce-keyboard {};
    organise-files = callPackage ./organise-files.nix {};
    tlauncher = callPackage ./tlauncher {};
    arc-x-icon-theme = callPackage ./arc-x-icons.nix {};
    auditor = callPackage ./auditor {};
    hyprshell = callPackage ./hyprshell.nix {};

    llama-cpp = pkgs-cuda.callPackage ./llama-cpp {};

    dockerImages = {
      llama-cpp = callPackages ./llama-cpp/docker.nix {};
    };

    dreamfinity = callPackage ./dreamfinity.nix {};

    jetbrains = {
      # I tried to find the source of invalid wmClass but it isn't in github:jetbrains/intellij-community
      # (also looking at build times it seems like derivation does not build from source. It should have been days instead)
      idea-oss = pkgs-jetbrains-oss.jetbrains.idea-oss.overrideAttrs(old: let
        desktopItem = old.desktopItem.override(old: {
          startupWMClass = assert old.startupWMClass == "jetbrains-idea-ce"; "jetbrains-idea";
        });
      in {
        installPhase = builtins.replaceStrings ["item=${old.desktopItem}"] ["item=${desktopItem}"] old.installPhase;
      });
      inherit (pkgs-jetbrains-oss.jetbrains) pycharm-oss;
    };

    traefik = callPackage ./traefik { traefik = pkgs-stable.legacyPackages."${system}".traefik; };

    krita = pkgs-krita.callPackage ./krita {
      krita-unwrapped = pkgs-krita.callPackage ./krita/unwrapped.nix {};
    };

    scrutiny-collector = callPackage ./scrutiny-collector.nix {};
    kent = callPackage ./kent {};
    ksrc = callPackage ./ksrc {}; 
  };
in flake-pkgs