{ buildGoModule, fetchFromGitHub, gitMinimal, ripgrep, ... }:

buildGoModule (final: {
  pname = "kent";
  version = "2.1.1";

  src = fetchFromGitHub {
    owner = "respawn-llc";
    repo = "kent";
    tag = "v${final.version}";
    hash = "sha256-dI3OO634p9/SIMc6oQRICwd1PAAIZ3UXNN+4dp2MlrE=";
  };

  vendorHash = "sha256-g+ekQEgAa9FiRjDAsyEm/9ONhH+D94WoCA+taxLUXwU=";

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    go build \
      -mod=vendor \
      -trimpath \
      -buildvcs=false \
      -ldflags "-s -w -X core/shared/config.Version=${final.version}" \
      -o "$out/bin/kent" \
      ./cli/kent

    runHook postInstall
  '';

  doCheck = false;

  nativeCheckInputs = [
    gitMinimal
    ripgrep
  ];
})
