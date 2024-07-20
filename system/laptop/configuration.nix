{ pkgs, ... }: {
  services.openssh.enable = false;
  
  environment.systemPackages = with pkgs; [
    wirelesstools
  ];
}
