{ traefik, ... }: let pkg = traefik.overrideAttrs(old: {
  patches = (old.patches or []) ++ [
    ./webtransport.patch
  ];
  vendorHash = "sha256-ULeiU/4dctvfOUPLD8CDZ0LkpUjyTOIEfsWJdhEJN9o=";

  passthru = old.passthru // {
    broken = true;
    tests = {};
    wt-client = pkg.overrideAttrs(old: {
      name = "wt-client";
      patches = (old.patches or []) ++ [
        ./wt-client.patch
      ];
      passthru = { inherit (old.passthru) overrideModAttrs; };
      subPackages = [ "cmd/wt-client" ];
      meta = {
        mainProgram = "wt-client";
      };
    });
  };
}); in pkg