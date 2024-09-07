{ pkgs }: pkgs.buildFHSUserEnv {
  name = "pycharm-fhs-env";
  targetPkgs = pkgs: (with pkgs;
    [
      libz # llama-index, numpy, or something, idk
   ]);
  runScript = "env";
}
