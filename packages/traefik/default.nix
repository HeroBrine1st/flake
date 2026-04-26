{ traefik, ... }: let pkg = traefik.overrideAttrs(old: {
  patches = (old.patches or []) ++ [
    ./webtransport.patch
  ];
  vendorHash = "sha256-ULeiU/4dctvfOUPLD8CDZ0LkpUjyTOIEfsWJdhEJN9o=";

  passthru = old.passthru // {
    tests = {};
    tunnel = pkg.overrideAttrs {
      passthru = {};
      subPackages = [ "cmd/traefik-tunnel-client" ];
      meta = {
        mainProgram = "traefik-tunnel-client";
      };
    };
  };
}); in pkg