{ pkgs }: pkgs.buildFHSEnv {
  name = "idea-fhs-env";
  targetPkgs = pkgs: (with pkgs;
    [
      libGL
      libz
   ]);
  runScript = "env";
}
