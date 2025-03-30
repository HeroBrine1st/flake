{ ags, pkgs }: ags.lib.bundle {
  inherit pkgs;
  src = ./.;
  name = "topbar";
  entry = "app.ts";
  gtk4 = true;
  extraPackages = builtins.attrValues (builtins.removeAttrs ags.packages.${pkgs.hostPlatform} ["docs"]);
}