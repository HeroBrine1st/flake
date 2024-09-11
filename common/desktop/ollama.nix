{ pkgs, ... }: {
  services.ollama = {
    enable = true;
    home = "/var/lib/ollama";
    user = "ollama";
    group = "ollama";
  };

  services.open-webui = {
    enable = true;
    stateDir = "/var/lib/open-webui";
  };
}