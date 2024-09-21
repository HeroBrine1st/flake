{ pkgs }: pkgs.buildFHSUserEnv {
  name = "android-fhs-env";
  targetPkgs = pkgs: (with pkgs;
    [
      libGL
      libz
      xorg.libXext # jetpack compose
   ]);
  runScript = "env";
}
