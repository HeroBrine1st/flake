{ letta-code, pkgs-unstable, system }:
let
  # letta-code's committed bun.nix is stale relative to its bun.lock (its build breaks on
  # missing packages), so we keep a freshly regenerated copy here. When the letta-code
  # tag is bumped, regenerate it with the bun2nix rev that letta-code's flake.lock pins:
  #   nix run "github:nix-community/bun2nix?rev=<bun2nix rev>#bun2nix" -- -l <letta-code>/bun.lock -o packages/letta-code/bun.nix
  lcPkgs = import pkgs-unstable {
    inherit system;
    # same nixpkgs the letta-code flake builds with (its nixpkgs follows our pkgs-unstable),
    # with the bun2nix overlay that letta-code itself pins
    overlays = [ letta-code.inputs.bun2nix.overlays.default ];
  };
in
letta-code.packages."${system}".letta-code.overrideAttrs (_: {
  bunDeps = lcPkgs.bun2nix.fetchBunDeps { bunNix = ./bun.nix; };
  # v0.33.2's preBuild patches `bunx tsc -p tsconfig.types.json` out of build.js, but
  # build.js still walks dist/types afterwards and fails with ENOENT. Let tsc run as-is:
  # typescript is in bun.lock, so bunx resolves it from the installed node_modules.
  preBuild = ''
    export HOME="$TMPDIR"
  '';
})
