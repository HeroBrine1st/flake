{
  imports = [
    ./nix.nix
    ./cli
    ./network/overlay
    #./scrutiny-collector.nix TODO enable only on bare metal machines
    ./syncthing.nix
    ./include-source.nix
  ];
}