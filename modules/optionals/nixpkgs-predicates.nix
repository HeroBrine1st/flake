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
    # default allowed
    nixpkgs.allowedNonSourcePackages = [
      "go" # bootstrapped, TODO should differentiate
      "cargo-bootstrap"
      "rustc-bootstrap-wrapper"
      "rustc-bootstrap"
      # https://github.com/NixOS/nixpkgs/blob/7c43f080a7f28b2774f3b3f43234ca11661bf334/nixos/modules/hardware/all-firmware.nix#L71
      # Dependency chain is not found. It is included in system.extraDependencies but unsure how
      "sof-firmware"
    ];

    nixpkgs.config = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) config.nixpkgs.allowedUnfreePackages;
      allowNonSourcePredicate = pkg: builtins.elem (lib.getName pkg) config.nixpkgs.allowedNonSourcePackages;
    };
  };
}