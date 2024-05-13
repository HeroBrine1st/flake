{
  stdenv,
  fetchurl,
}: stdenv.mkDerivation {
  pname = "mali-g610-firmware";
  version = "unstable-2023-06-08";

  src = fetchurl {
    url = "https://github.com/tsukumijima/libmali-rockchip/raw/2d267b0ab97b9116a75f8b606204297a200db37c/firmware/g610/mali_csffw.bin";
    hash = "";
  };

  buildCommand = ''
    install -Dm444 $src $out/lib/firmware/mali_csffw.bin
  '';
}