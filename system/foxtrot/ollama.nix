{ pkgs, unstable-pkgs, ... } : {
  services.ollama = {
    enable = true;
    package = unstable-pkgs.ollama;
  };

  services.open-webui = {
    enable = true;
    package = unstable-pkgs.open-webui;
    environment = {
      # defconf #
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
      # defconf #

      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      WEBUI_AUTH = "False";
    };
  };
}