{ ags, pkgs }: ags.lib.bundle {
  inherit pkgs;
  src = ./.;
  name = "topbar";
  entry = "app.ts";
  gtk4 = true;
}