{ pkgs-unstable, pkgs-stable, fenix, ags, pkgs-bdfr, system, ... }@inputs: let
  lib = pkgs.lib;
  pkgs = pkgs-unstable.legacyPackages."${system}";
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

    llama-cpp = (pkgs-cuda.llama-cpp.override {
      rpcSupport = true;
      cudaSupport = true;
    }).overrideAttrs (old: {
      version = assert lib.versionOlder old.version "9505"; "9505";
      src = old.src.override { hash = "sha256-HH60dBpTUWgMSkM1y6JhMVrK6Rookn+Xhm2qQxDbQKs="; };
      npmDepsHash = "sha256-1iM0LGeI9e+gZEHk46lkBe51DxIhiimfAm9o3Z3m9Ik=";
      patches = (old.patches or []) ++ [
        (builtins.toFile "consider-mmproj-offload-in-vram-reservation.patch" ''
          diff --git a/tools/server/server-context.cpp b/tools/server/server-context.cpp
          index bfe3443c..800da19b 100644
          --- a/tools/server/server-context.cpp
          +++ b/tools/server/server-context.cpp
          @@ -769,7 +769,7 @@ private:
                   }

                   // optionally get the memory usage of mmproj
          -        if (has_mmproj && params_base.fit_params) {
          +        if (has_mmproj && params_base.fit_params && params_base.mmproj_use_gpu) {
                       auto mmproj_mem = mtmd_get_memory_usage(mmproj_path.c_str(), mparams);
                       if (!mmproj_mem.empty()) {
                           size_t total = 0;

        '')
      ];
    });

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

    letta-code = callPackage ./letta-code {};
    traefik = callPackage ./traefik { traefik = pkgs-stable.legacyPackages."${system}".traefik; };

    krita = pkgs-krita.callPackage ./krita {
      krita-unwrapped = pkgs-krita.callPackage ./krita/unwrapped.nix {};
    };

    scrutiny-collector = callPackage ./scrutiny-collector.nix {};
  };
in flake-pkgs