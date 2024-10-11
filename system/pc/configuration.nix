{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (pkgs.callPackage ../../packages/edmarketconnector.nix {})
  ];

  environment.etc."htoprc".source = ./htoprc;
}
