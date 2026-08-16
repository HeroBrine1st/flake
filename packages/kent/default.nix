{ buildGoModule, fetchFromGitHub, gitMinimal, ripgrep, ... }:

buildGoModule (final: {
  pname = "kent";
  version = "2.7.1";

  src = fetchFromGitHub {
    owner = "respawn-llc";
    repo = "kent";
    tag = "v${final.version}";
    hash = "sha256-1EINBtWs6/pr0C8GAZEiUWptZqVsQeRo4KB48veReqs=";
  };

  vendorHash = "sha256-hMm1+J3tmSj9fpIumCM4JeVdyHLoKe9W2yNFq/BgiNQ=";

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
