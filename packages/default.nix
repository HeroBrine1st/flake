{ pkgs-jetbrains-2022, pkgs-unstable, fenix, ags, pkgs-bdfr, system, nixpakRaw }: let
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
    jetbrains = (import pkgs-jetbrains-2022 { inherit system; config.allowUnfreePredicate = pkgsNamed [ "idea-ultimate" "pycharm-professional" "clion" ]; }).jetbrains;
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

    nixpak = let
      mkNixPak = import (nixpakRaw + "/modules") { inherit pkgs lib; }; # strictly avoiding unnecessary code
      sloth = import (nixpakRaw + "/modules/lib/sloth.nix") {
        inherit lib sloth;
        config = throw "appDir is explicitly not supported";
      };
    in {
      inherit (sloth._module.args) sloth;
      mkSandbox = config: (mkNixPak { inherit config; }).config.env;
    };
  };
in custom-pkgs