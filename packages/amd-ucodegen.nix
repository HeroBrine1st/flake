# Credits to https://github.com/e-tho/ucodenix/blob/dfcd427c945c80b135725f43e0a716cdf710b9c5/flake.nix#L10-L36
# This derivation is copied from flake in order to decrease supply chain attack surface

# This program roughly copies input files to output files, adding headers between blocks
{ stdenv }: stdenv.mkDerivation rec {
  pname = "amd-ucodegen";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "AndyLavr";
    repo = "amd-ucodegen";
    # memory-unsafe-C code
    # DO NOT CHANGE WITHOUT MANUAL CODE REVIEW
    rev = "0d34b54e396ef300d0364817e763d2c7d1ffff02";
    sha256 = "pgmxzd8tLqdQ8Kmmhl05C5tMlCByosSrwx2QpBu3UB0=";
  };

  nativeBuildInputs = [ pkgs.makeWrapper ];

  makeTarget = "";

  installPhase = ''
    mkdir -p $out/bin
    cp amd-ucodegen $out/bin/
  '';

  meta = with pkgs.lib; {
    description = "This tool generates AMD microcode containers as used by the Linux kernel.";
    homepage = "https://github.com/AndyLavr/amd-ucodegen";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}