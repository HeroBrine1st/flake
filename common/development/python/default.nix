{ pkgs, ...}: {
  environment.systemPackages = [
    (pkgs.pipenv.overrideAttrs (old: {
      patches = (old.patches or []) ++ [
        ./pipenv-venv-in-project.patch
      ];
    }))
  ];

  environment.python = {
    enable = true;
    modules = pythonPkgs: with pythonPkgs; [
      jupyter
      notebook
      numpy
      pandas
    ];
  };
}
