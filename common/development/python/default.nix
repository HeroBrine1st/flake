{ pkgs, ...}: {
  environment.systemPackages = [
    (pkgs.pipenv.overrideAttrs (old: {
      patches = (old.patches or []) ++ [
        ./pipenv-venv-in-project.patch
      ];
    }))
  ];
}
