{ pkgs }: pkgs.buildFHSUserEnv {
  name = "android-fhs-env";
  targetPkgs = pkgs: (with pkgs;
    [
      libGL
      libz
   ]);
  runScript = "env";
}
