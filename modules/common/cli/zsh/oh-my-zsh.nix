{ pkgs, ... }: {
  programs.zsh.ohMyZsh = {
    enable = true;
    customPkgs = [
      # The zsh module copies ${customPkgs[@]/#/share/zsh} but powerlevel has wrong derivation layout
      (pkgs.runCommandLocal "powerlevel10k-pluggable" {} ''
        install -d $out/share/zsh/themes/
        ln -s ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k $out/share/zsh/themes/powerlevel10k
      '')
    ];
    theme = "powerlevel10k/powerlevel10k";
    plugins = [
      "git"
    ];
  };
}