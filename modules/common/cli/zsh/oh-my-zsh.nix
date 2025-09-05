{ pkgs, lib, ... }: {
  programs.zsh.ohMyZsh = {
    enable = true;
    customPkgs = [
      (let
        powerlevel10k = pkgs.zsh-powerlevel10k.overrideAttrs(old: {
          patches = old.patches ++ [
            ./powerlevel10k-flexible-git.patch
          ];
        });
        # The zsh module copies ${customPkgs[@]/#/share/zsh} but powerlevel has wrong derivation layout
      in pkgs.runCommandLocal "powerlevel10k-pluggable" {} ''
        install -d $out/share/zsh/themes/
        ln -s ${powerlevel10k}/share/zsh-powerlevel10k $out/share/zsh/themes/powerlevel10k
      '')
    ];
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