{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (pkgs.callPackage ../../packages/edmarketconnector.nix {})
  ];
}
