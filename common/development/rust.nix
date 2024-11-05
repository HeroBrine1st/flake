{ custom-pkgs, ... }: {
  environment.systemPackages = [
    custom-pkgs.rust-with-src
  ];
}