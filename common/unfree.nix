{ lib, ... }: {
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "nvidia-x11" "nvidia-settings" "nvidia-persistenced"
    "spotify"
    "android-studio-stable"
    "rust-rover"
    "steam" "steam-original" "steam-run"
    "osu-lazer-bin"
    "veracrypt"
    "code" "vscode"
    "winbox"
  ];
}
