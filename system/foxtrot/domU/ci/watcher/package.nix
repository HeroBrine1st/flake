{ python3Packages }:

python3Packages.buildPythonApplication {
  pname = "ci-watchers";
  version = "0";
  pyproject = true;

  src = ./.;

  nativeBuildInputs = [ python3Packages.setuptools ];

  propagatedBuildInputs = with python3Packages; [
    anyio
    httpx
    pydantic
    pydantic-settings
  ];
}
