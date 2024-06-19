{ pkgs }: pkgs.buildFHSUserEnv {
  name = "pycharm-fhs-env";
  targetPkgs = pkgs: (with pkgs;
    [
      
   ]);
  runScript = "env";
}
