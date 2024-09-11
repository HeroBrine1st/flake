{ options, config, lib, ... }: with lib; {
  options.nixpkgs.allowedUnfreePackages = mkOption {
    type = types.listOf types.str;
    description = "List of unfree packages to ignore";
  };

  config = {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) config.nixpkgs.allowedUnfreePackages;
  };
}