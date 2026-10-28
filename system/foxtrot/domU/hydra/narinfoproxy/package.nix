{ python3Packages }: python3Packages.buildPythonApplication {
  pname = "narinfo-proxy";
  version = "0";
  pyproject = true;

  src = ./.;

  nativeBuildInputs = [ python3Packages.setuptools ];

  propagatedBuildInputs = with python3Packages; [
    anyio
    fastapi
    httpx
    pydantic-settings
    uvicorn
  ];
}
