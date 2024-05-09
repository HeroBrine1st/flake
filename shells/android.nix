{ pkgs }: (pkgs.buildFHSUserEnv {
  name = "android-env";
  targetPkgs = pkgs: (with pkgs;
    [
      glibc
      libGL
    ]);
  runScript = "bash";
}).env