{ stdenvNoCC, python3 }: let
  python = python3.withPackages(pythonPkgs: with pythonPkgs; [
    libevdev
  ]);
in stdenvNoCC.mkDerivation {
  name = "chattering-fix";
  version = "1.0";

  src = ./.;

  buildInputs = [
    python
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp $src/script.py $out/bin/debounce-keyboard
    chmod +x $out/bin/debounce-keyboard
  '';
}
