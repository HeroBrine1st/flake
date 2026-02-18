{ pkgs, ...}: {
  environment.systemPackages = [
    (pkgs.pipenv.overrideAttrs (old: {
      patches = (old.patches or []) ++ [
        ./pipenv-venv-in-project.patch
      ];
    }))
  ];

  programs.python = {
    enable = true;
    modules = pythonPkgs: with pythonPkgs; [
      jupyter
      notebook
      numpy
      scipy
      matplotlib
      mplcursors
      pandas
      seaborn
      scipy
      scikit-learn
      optuna
      # manually reviewed and pinned; unlikely to get updated
      (assert timeout-decorator.src.outputHash == "6a2f2f58db1c5b24a2cc79de6345760377ad8bdc13813f5265f6c3e63d16b3d7" && timeout-decorator.src.outputHashAlgo == "sha256"; timeout-decorator)
      tensorflow
      keras
    ];
  };
}
