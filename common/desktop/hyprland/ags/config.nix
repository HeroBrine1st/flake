{ typescript, runCommand, dart-sass, symlinkJoin, ags, ... }: let
  source = symlinkJoin { # can't symlink beforehand due to permission denied even after copying to build folder and chmodding
    name = "ags-config-source";
    paths = [
      ./config
      (runCommand "ags-types" {} ''
        # include only types folder and rename it to workaround typeRoots breaking build
        # another way is patching tsconfig.json to remove typeRoots
        mkdir $out
        ln -s "${ags}/share/com.github.Aylur.ags/types" "$out/types-nix"
      '')
    ];
  };
in runCommand "ags-config" {} ''
  ${typescript}/bin/tsc --project "${source}" --outDir "$out"
  ${dart-sass}/bin/dart-sass --load-path=${./style} ${./style}/style.scss "$out/style.css"
  rm "$out/style.css.map"
''