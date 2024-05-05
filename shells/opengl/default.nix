{pkgs, lib, stdenv}: stdenv.mkDerivation {
  name = "opengl-dev";
  buildInputs = with pkgs; [
    cmake
    gnumake
    pkg-config
    libGL
    glm
    glew
    freeglut
    wayland
    libxkbcommon
    xorg.libX11
    xorg.libXrandr
    xorg.libXinerama
    xorg.libXcursor
    xorg.libXi
  ];
#  propagatedBuildInputs = with pkgs; [
#
#  ];
}