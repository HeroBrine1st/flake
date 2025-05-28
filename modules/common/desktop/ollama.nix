{ pkgs, ... }: {
  services.ollama = {
    enable = true;
  };

  services.open-webui = {
    enable = true;
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

  nixpkgs.allowedNonSourcePackages = [
    "temurin-bin" # transitive dependency of open-webui (pydub -> ffmpeg -> jdk_headless)
  ];
}