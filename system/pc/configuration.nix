{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (pkgs.callPackage ../../packages/edmarketconnector.nix {})
  ];

  environment.etc."htoprc".source = ./htoprc;

  nix.settings = {
    substituters = [
      "https://cuda-maintainers.cachix.org"
    ];
    trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  networking.firewall.allowedUDPPorts = [ 34197 ]; # factorio
}
