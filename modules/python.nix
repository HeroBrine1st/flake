{ lib, pkgs, config, options, ... }: with lib; let
  pythonModulesType = mkOptionType {
    name = "pythonModulesType";
    description =
      "A function types.package -> types.listOf types.package";
    check = value: builtins.isFunction value;
    merge = loc: defs:
      pythonPkgs: concatMap (def: def.value pythonPkgs) defs;
  };
in {
  options.environment.python = {
    enable = lib.mkEnableOption "python environment";
    package = lib.mkPackageOption pkgs "python3" {};
    modules = mkOption {
      type = pythonModulesType;
      default = _: [];
      description = "Function returning list of modules to be installed into python environment";
      example = lib.literalExpression "pythonPkgs: with pythonPkgs; [ rich ]";
    };
  };
  config = lib.mkIf config.environment.python.enable {
    environment.systemPackages = [
      (config.environment.python.package.withPackages config.environment.python.modules)
    ];
  };
}