{ buildGoModule, fetchFromGitHub, ... }: buildGoModule (final: {
  pname = "ksrc";
  version = "0.6.3";

  src = fetchFromGitHub {
    owner = "respawn-llc";
    repo = "ksrc";
    tag = "v${final.version}";
    hash = "sha256-Rjovku9ltjMOWjh8e19HPAlpNu+p5I5qXmdZa2aMlQQ=";
  };

  vendorHash = "sha256-xowY1N6qJ23WYs1XIwM6xoD6fMRxfGQtFyRpOqCfkiE=";
})
