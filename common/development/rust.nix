{ custom-pkgs, pkgs, ... }: {
  environment.systemPackages = [
    custom-pkgs.rust-with-src
    pkgs.espflash
  ];
}