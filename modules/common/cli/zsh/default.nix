{ lib, pkgs, options, ... }: {
  imports = [
    ./oh-my-zsh.nix
  ];
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    histSize = 16777216; # practically unlimited
    setOptions = [
      "HIST_IGNORE_DUPS"
      "AUTO_CD"
      "NOCLOBBER"
      "NOAUTO_MENU"

      # "SHARE_HISTORY" - requires .bash_history migration as it enables "EXTENDED_HISTORY"
      # "HIST_FCNTL_LOCK" - may provide performance improvement (is there any problem?)
    ];
    # See zshparam.1 ("ARRAY PARAMETERS", describes ${var[@}}) and zshexpn.1 ("PARAMETER EXPANSION")
    # zshmisc.1 has info on statemennts (if/while/for and conditions (-e, -f))
    # zshbuiltins.1
    shellInit = ''
      # Enforce ZDOTDIR
      UNSAFE_DOTFILES=(.zshenv .zprofile .zshrc .zlogin .zlogout)
      for file in "''${UNSAFE_DOTFILES[@]/#/$HOME/}"; do
        if [[ -e $file ]]; then
          echo "Found file $file" >&2
          echo "Listing contents:"
          sed 's/^/    /' "$file"
          read -q "REPLY?Remove file? "
          if [[ $REPLY == "y" ]]; then
            echo "Removing file $file"
            rm -vf "$file"
          else
            echo "Exiting"
            exit 2
          fi
        fi
      done
      unset UNSAFE_DOTFILES
    '';
    interactiveShellInit = lib.mkAfter ''
      tab-complete-or-nothing() {
        # with empty buffer it inserts tab characters
        if [[ -z $BUFFER ]]; then
          print -n "\a" # beep
          return 0
        else
          zle expand-or-complete
          if [[ $? -ne 0 ]]; then
            print -n "\a" # beep
          fi
        fi
      }
      zle -N tab-complete-or-nothing

      bindkey '^I' tab-complete-or-nothing

      zle_beep_backspace() {
        if [[ -z $BUFFER ]]; then
          print -n "\a" # beep
        else
          zle backward-delete-char
        fi
      }
      zle -N zle_beep_backspace
      bindkey '^?' zle_beep_backspace

      bindkey '^[[A' history-beginning-search-backward
      bindkey '^[OA' history-beginning-search-backward
      bindkey '^[[B' history-beginning-search-forward
      bindkey '^[OB' history-beginning-search-forward
    '';
  };

  environment.variables = {
    # Fix a path for malware to gain root privileges combined with https://github.com/systemd/systemd/issues/33902
    # (yet another confirmation that secure system does not have root)
    # Also drastically reduces attack surface by distructing persistent state
    # This is enforced with init script
    # Also this disables prompt to create ~/.zshrc (which bash successfully avoided by sane default /etc/bashrc and as such zsh should too)
    ZDOTDIR = pkgs.emptyDirectory;
  };
}