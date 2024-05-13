{ stdenv, stdenvNoCC, fetchFromGitHub, autoPatchelfHook, libdrm, wayland, libxcb, libX11, ... }: let
  src = fetchFromGitHub {
    owner = "tsukumijima";
    repo = "libmali-rockchip";
    rev = "2d267b0ab97b9116a75f8b606204297a200db37c";
    hash = "";
  };
in {
  libmali-valhall-g610-g13p0-x11-wayland-gbm = stdenv.mkDerivation rec {
    pname = "libmali-valhall-g610";
    version = "g13p0";
    variant = "x11-wayland-gbm";
    dontConfigure = true;

    inherit src;

    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ stdenv.cc.cc.lib libdrm wayland libxcb libX11 ];

    preBuild = ''
      addAutoPatchelfSearchPath ${stdenv.cc.cc.lib}/aarch64-unknown-linux-gnu/lib
    '';

    installPhase = let
      libmaliFileName = "${pname}-${version}-${variant}.so";
    in ''
      runHook preInstall

      mkdir -p $out/lib
      mkdir -p $out/etc/OpenCL/vendors
      mkdir -p $out/share/glvnd/egl_vendor.d

      ls -lh lib/aarch64-linux-gnu/

      install --mode=755 lib/aarch64-linux-gnu/${libmaliFileName} $out/lib
      echo $out/lib/${libmaliFileName} > $out/etc/OpenCL/vendors/mali.icd
      cat > $out/share/glvnd/egl_vendor.d/60_mali.json << EOF
      {
        "file_format_version" : "1.0.0",
        "ICD" : {
          "library_path" : "$out/lib/${libmaliFileName}"
        }
      }
      EOF

      runHook postInstall
    '';
  };
}