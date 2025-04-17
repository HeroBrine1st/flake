{ modulesPath, ... }: {
  imports = [
    ./configuration.nix
    ./impermanence.nix
    ./hardware-configuration.nix
    (modulesPath + "/profiles/qemu-guest.nix")
    ./traefik.nix
  ];

  services.traefik = {
    # TODO move traefik to module and move that out of here
    enableInDocker = true;
    group = "docker";
  };
}