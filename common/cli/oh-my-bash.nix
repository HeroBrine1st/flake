{ pkgs, modulesPath, ... }: let
  oh-my-bash = pkgs.fetchFromGitHub {
    owner = "ohmybash";
    repo = "oh-my-bash";
    rev = "86efbf1bdcf53da302bb2ae3cdce281ddabdd18d";
    hash = "sha256-TinljV9Q72xoAZoh9KaTv9DlfsrnuBGSdyZhtXWbQAg=";
  };
  # TODO shellcheck
  omb-init = pkgs.writeScript "oh-my-bash-rc" ''
    # Enable the subsequent settings only in interactive sessions
    case $- in
      *i*) ;;
        *) return;;
    esac

    if [[ "$USER" == "root" ]]; then
      return
    fi

    # Path to your oh-my-bash installation.
    export OSH=${oh-my-bash}

    # Set name of the theme to load. Optionally, if you set this to "random"
    # it'll load a random theme each time that oh-my-bash is loaded.
    OSH_THEME="powerline"

    # Uncomment the following line to use case-sensitive completion.
    CASE_SENSITIVE="true"

    # Uncomment the following line to use hyphen-insensitive completion. Case
    # sensitive completion must be off. _ and - will be interchangeable.
    # HYPHEN_INSENSITIVE="true"

    DISABLE_AUTO_UPDATE="true"

    # Uncomment the following line to disable colors in ls.
    # DISABLE_LS_COLORS="true"

    # Uncomment the following line to disable auto-setting terminal title.
    # DISABLE_AUTO_TITLE="true"

    # Uncomment the following line to enable command auto-correction.
    # ENABLE_CORRECTION="true"

    # Uncomment the following line to display red dots whilst waiting for completion.
    COMPLETION_WAITING_DOTS="true"

    # Uncomment the following line if you want to disable marking untracked files
    # under VCS as dirty. This makes repository status check for large repositories
    # much, much faster.
    # DISABLE_UNTRACKED_FILES_DIRTY="true"

    OMB_USE_SUDO=false

    completions=(
      git
      composer
      # ssh # conflicts with bash-completions
    )

    aliases=(
      general
    )

    plugins=(
      git
      bashmarks
    )

    source "$OSH"/oh-my-bash.sh

    alias mkdir="mkdir >/dev/null"
    alias ytmusic="yt-dlp -f bestaudio --extract-audio -o '%(playlist_index)s. %(title)s.%(ext)s'"
    alias ytvideo="yt-dlp --write-sub --sub-lang ru,en.* --sponsorblock-mark all --embed-metadata --merge-output-format mkv"

    alias "engage-buildkit-multiplatform=docker run --rm --privileged multiarch/qemu-user-static --reset -p yes"
    alias xclip="xclip -selection c"
    alias killall="killall -I"

    dockersend() {
        docker save "''${@:2}" -o image.tar && (pv image.tar | ssh $1 "docker load") && rm image.tar
    }

    LS_COLORS=$LS_COLORS:'di=0;36:' #; export LS_COLORS
    PATH="/home/$USER/.local/bin:$PATH"

    unset CDPATH
    complete -d cd

    HISTSIZE=-1
    HISTFILESIZE=-1
  '';
in {
  programs.bash.promptInit = ''
    source ${omb-init}
  '';

  environment.etc.inputrc.text = builtins.readFile (modulesPath + "/programs/bash/inputrc") + ''
    set show-all-if-ambiguous on
    set bell-style audible
  '';
}