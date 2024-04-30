{ bash-completion, pkgs, fetchurl }: bash-completion.overrideAttrs (old: rec {
  version = "2.11";
  src = pkgs.fetchurl {
    url = "https://github.com/scop/${old.pname}/releases/download/${version}/${old.pname}-${version}.tar.xz";
    sha256 = "sha256-c6iJS62U3ug6tGj6CfYo2v/VZ+i+8aJCd/HpoNr5Eaw=";
  };
})