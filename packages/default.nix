{ pkgs-jetbrains-2022, pkgs-unstable, fenix, ags, system }: let
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
  };
in custom-pkgs