# I don't see any reason to fetch "crane" just to build that.. I understand it supports incremental building, but that's for developers
{ rustPlatform, fetchFromGitHub, gtk4, gtk4-layer-shell, pkg-config }: rustPlatform.buildRustPackage rec {
  pname = "hyprshell";
  version = "4.5.0";

  src = fetchFromGitHub {
    owner = "H3rmt";
    repo = "hyprshell";
    rev = "v${version}";
    hash = "sha256-AfOG2MCHRp/p894mJhCRRGTLd+DpWKAp3Epf5dR7S/E=";
  };

  buildInputs = [
    gtk4
    gtk4-layer-shell
  ];

  nativeBuildInputs = [
    pkg-config
  ];

  cargoHash = "sha256-+yjqbTPmfqXGJ85J2+Muhe2/mL1UyBi2XdafY9Mp+Os";
}