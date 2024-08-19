# buildPythonApplication simply does not emit any executable at resulting derivation
# no build system being configured is probably the reason
{ fetchFromGitHub, python3, writeShellApplication }: let
  version = "5.11.3";
  src = fetchFromGitHub {
    owner = "EDCD";
    repo = "EDMarketConnector";
    rev = "Release/${version}";
    hash = "sha256-R+MhhPtQeiEFjtxDqSGT2xPHVV6me/ELU/t90jPSsfQ=";
  };
  runtime = python3.withPackages (pythonPkgs: with pythonPkgs; [
    requests
    pillow
    watchdog
    semantic-version

    tkinter # isn't included in requirements.txt
  ]);
in writeShellApplication  {
  name = "edmarketconnector";
  text = ''PYTHONPATH="${src}" "${runtime}/bin/python" "${src}/EDMarketConnector.py"'';
}