{
  nixpkgs.allowedUnfreePackages = [
    "nvidia-x11" "nvidia-settings" "nvidia-persistenced"
    "cuda_nvcc" "cuda_cudart" "libcublas" "cuda_cccl" # ollama nvidia
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
