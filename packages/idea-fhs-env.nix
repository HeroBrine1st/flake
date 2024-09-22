{ pkgs }: pkgs.buildFHSUserEnv {
  name = "idea-fhs-env";
  targetPkgs = pkgs: (with pkgs;
    [
      libGL
      libz
   ]);
  runScript = "env";
}
