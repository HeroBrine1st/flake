{ pkgs-unstable, fenix, ags, pkgs-bdfr, system }: let
  lib = pkgs.lib;
  pkgs = pkgs-unstable.legacyPackages."${system}";
  pkgsNamed = names: pkg: builtins.elem (lib.getName pkg) names;
  pkgs-cuda = import pkgs-unstable {
    inherit system;
    config.allowUnfreePredicate = pkgsNamed [ "cuda_cccl" "cuda_cudart" "libcublas" "cuda_nvcc" ];
  };
  all-pkgs = pkgs // custom-pkgs // { pkgs = all-pkgs; };
  callPackage = lib.customisation.callPackageWith all-pkgs;
  callPackages = lib.customisation.callPackagesWith all-pkgs;
  custom-pkgs = {
    inherit callPackage callPackages custom-pkgs;
    fenix = (import pkgs-unstable { inherit system; overlays = [ fenix.overlays.default ]; }).fenix;
    topbar = import ./topbar { inherit pkgs ags; };

    bdfr = pkgs-bdfr.legacyPackages."${system}".callPackage ./bdfr {};
    debounce-keyboard = callPackage ./debounce-keyboard {};
    organise-files = callPackage ./organise-files.nix {};
    tlauncher = callPackage ./tlauncher {};
    arc-x-icon-theme = callPackage ./arc-x-icons.nix {};
    auditor = callPackage ./auditor {};
    hyprshell = callPackage ./hyprshell.nix {};

    llama-cpp = pkgs-cuda.llama-cpp.override {
      rpcSupport = true;
      cudaSupport = true;
    };

    dockerImages = {
      llama-cpp = callPackages ./llama-cpp/docker.nix {};
    };

    dreamfinity = callPackage ./dreamfinity.nix {};

    jetbrains = {
      # I tried to find the source of invalid wmClass but it isn't in github:jetbrains/intellij-community
      # (also looking at build times it seems like derivation does not build from source. It should have been days instead)
      idea-oss = pkgs.jetbrains.idea-oss.overrideAttrs(old: let
        desktopItem = old.desktopItem.override(old: {
          startupWMClass = assert old.startupWMClass == "jetbrains-idea-ce"; "jetbrains-idea";
        });
      in {
        installPhase = builtins.replaceStrings ["item=${old.desktopItem}"] ["item=${desktopItem}"] old.installPhase;
      });
    };
  };
in custom-pkgs