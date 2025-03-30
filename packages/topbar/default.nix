{ ags, pkgs }: ags.lib.bundle {
  inherit pkgs;
  src = ./.;
  name = "topbar";
  entry = "app.ts";
  gtk4 = false;
  extraPackages = with ags.packages.${system}; [ hyprland mpris battery wireplumber network tray ];
}