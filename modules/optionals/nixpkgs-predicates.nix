{ options, config, lib, ... }: with lib; {
  options = {
    nixpkgs.allowedUnfreePackages = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of unfree packages to allow";
    };
    nixpkgs.allowedNonSourcePackages = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of non-source packages to allow";
    };
  };
  config = {
    nixpkgs.config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) config.nixpkgs.allowedUnfreePackages;
      allowNonSourcePredicate = pkg: builtins.elem (lib.getName pkg) config.nixpkgs.allowedNonSourcePackages;
    };
  };
}