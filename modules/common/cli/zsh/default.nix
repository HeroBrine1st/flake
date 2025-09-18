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
      "HIST_FIND_NO_DUPS"
      "APPEND_HISTORY"
      "INC_APPEND_HISTORY"
      "EXTENDED_HISTORY"

      # "HIST_FCNTL_LOCK" - may provide performance improvement (is there any problem?)
    ];
    # See zshparam.1 ("ARRAY PARAMETERS", describes ${var[@}}) and zshexpn.1 ("PARAMETER EXPANSION")
    # zshmisc.1 has info on statemennts (if/while/for and conditions (-e, -f))
    # zshbuiltins.1
    shellInit = ''
      # Enforce ZDOTDIR
      # Also check bash files because bash is sometimes triggered via nix-shell etc (and bash has no way to disable it - that's the only reason it is replaced with zsh. The only)
      # xprofile and xinitrc to complete the picture
      UNSAFE_DOTFILES=(.zshenv .zprofile .zshrc .zlogin .zlogout .bash_profile .bashrc .bash_logout .xprofile .xinitrc)
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
      # Intellij IDEA is noticed overriding ZDOTDIR via environment variable then setting HISTFILE to $ZDOTDIR/.zsh_history
      # This breaks shell integration flake-wide and fixes HISTFILE
      # No actual payload is found in shell integration. That shell integration likely does nothing.
      ZDOTDIR=${pkgs.emptyDirectory};
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

      # The logic: on down-history/up-history save the LBUFFER, and if it is still the same, use down-history or up-history again and update the variable
      # Otherwise, search by prefix
      last_lbuffer=""

      arrow-up() {
        if [[ -z $BUFFER || "$last_lbuffer" = "$LBUFFER" ]]; then
          zle up-history
          last_lbuffer="$LBUFFER"
        else
          last_lbuffer=""
          zle history-beginning-search-backward
        fi
      }
      zle -N arrow-up

      bindkey '^[[A' arrow-up
      bindkey '^[OA' arrow-up

      arrow-down() {
        if [[ -z $BUFFER || "$last_lbuffer" = "$LBUFFER" ]]; then
          zle down-history
          last_lbuffer="$LBUFFER"
        else
          last_lbuffer=""
          zle history-beginning-search-forward
        fi
      }
      zle -N arrow-down

      bindkey '^[[B' arrow-down
      bindkey '^[OB' arrow-down

      bindkey '^[[1;5B' down-line
      bindkey '^[[1;5A' up-line
      # and left-right for mindless usage
      bindkey '^[[1;5C' forward-char
      bindkey '^[[1;5D' backward-char

      [[ -d "$HOME/.zsh" ]] || mkdir -p "$HOME/.zsh"
      if [[ -f "$HOME/.zsh_history" ]]; then
        if [[ ! -f "$HOME/.zsh/history" ]]; then
          mv "$HOME/.zsh_history" "$HOME/.zsh/history"
        elif [[ -s "$HOME/.zsh_history" ]]; then
          echo "WARNING: Found rogue $HOME/.zsh_history file"
        else
          rm "$HOME/.zsh_history"
        fi
      fi
      HISTFILE="$HOME/.zsh/history"
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