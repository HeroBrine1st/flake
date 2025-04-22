{
  imports = [
    ./cli
    ./network/overlay
    #./scrutiny-collector.nix TODO enable only on bare metal machines
    #./syncthing.nix TODO opi5 has it in docker
  ];
}