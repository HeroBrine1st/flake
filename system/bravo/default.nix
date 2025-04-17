{ modulesPath, ... }: {
  imports = [
    ./configuration.nix
    ./impermanence.nix
    ./hardware-configuration.nix
    (modulesPath + "/profiles/qemu-guest.nix")
    ./traefik.nix
  ];

  services.traefik.enableInDocker = true; # TODO tmp
}