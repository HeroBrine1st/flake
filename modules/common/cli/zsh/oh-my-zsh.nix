{ pkgs, lib, ... }: {
  programs.zsh.ohMyZsh = {
    enable = true;
    # custom instead of customPkgs due to https://github.com/NixOS/nixpkgs/commit/fbe214434a678004f8631a8f893d5c089e534db9
    # not being up to date with https://github.com/NixOS/nixpkgs/blob/89c2b2330e733d6cdb5eae7b899326930c2c0648/nixos/modules/programs/zsh/oh-my-zsh.nix#L18
    # pathsToLink is not a list, leading to error:
    # pkgs.buildEnv error: Can't use string ("/share/zsh/plugins") as an ARRAY ref while "strict refs" in use at /nix/store/...-builder.pl line 18.
    custom = let
      powerlevel10k = pkgs.zsh-powerlevel10k.overrideAttrs(old: {
        patches = old.patches ++ [
          ./powerlevel10k-flexible-git.patch
        ];
      });
      derivation = pkgs.runCommandLocal "zsh-custom" {} ''
        install -d $out/themes
        ln -s ${powerlevel10k}/share/zsh/themes/powerlevel10k $out/themes/powerlevel10k
      '';
      # and for some reason it wants string not path
    in "${derivation}";
    preLoaded = ''
      source ${./p10k.zsh}
    '';
    theme = "powerlevel10k/powerlevel10k";
    plugins = [
      "git"
    ];
  };
  programs.zsh.interactiveShellInit = lib.mkAfter ''
    setopt NOSHARE_HISTORY
  '';
}