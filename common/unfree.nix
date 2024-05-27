{ lib, ... }: {
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "nvidia-x11" "nvidia-settings" "nvidia-persistenced"
    "spotify"
    "android-studio-stable"
    "idea-ultimate"
    "pycharm-professional"
    "webstorm"
    "clion"
    "rust-rover"
    "steam" "steam-original"
    "osu-lazer-bin"
    "veracrypt"
    "code" "vscode"
    "winbox"
  ];
}