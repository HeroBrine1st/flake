{ llama-cpp, lib, fetchFromGitHub, cudaPackages}: (llama-cpp.override {
  rpcSupport = true;
  cudaSupport = true;
}).overrideAttrs (final: old: {
  #pname = "beellama-cpp";
  #version = "0.3.1";
  #src = fetchFromGitHub {
  #  owner = "Anbeeld";
  #  repo = "beellama.cpp";
  #  rev = "v${final.version}";
  #
  #  hash = "sha256-sKoFROgpOE8bsFTAe34suJ5j9DWln5wlBxR0MVuhKgQ=";
  #};
  #npmDepsHash = "sha256-1iM0LGeI9e+gZEHk46lkBe51DxIhiimfAm9o3Z3m9Ik=";
  
  #version = let v = "9747"; in assert lib.versionOlder old.version v; v;
  src = old.src.override {
    tag = "b${final.version}";
    hash = "sha256-ecXJxidnlQRAyDftYIcTrER5U3+YQ+XfvAxA29pj+uI=";
  };
  buildInputs = old.buildInputs ++ [
    cudaPackages.nccl
  ];
  npmDepsHash = "sha256-0dctM/apI3ysMIEVBaBXO9hZMWskpJpNpOws1gwiOYc=";
  cmakeFlags = old.cmakeFlags ++ [
    # https://github.com/Anbeeld/beellama.cpp/blob/main/docs/quickstart-qwen36-dflash.md
    # required for TurboQuant and TCQ cache types
    # and possibly for q6.patch
    (lib.cmakeBool "GGML_CUDA_FA_ALL_QUANTS" true)
    (lib.cmakeBool "GGML_CUDA_NCCL" true)
    (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "86;75")
    #(lib.cmakeFeature "LLAMA_BUILD_NUMBER" "000301") # it is an integer
  ];
  patches = (old.patches or []) ++ [
    # This one is embedded in beellama.cpp
    ./consider-mmproj-offload-in-vram-reservation.patch
    ./q6.patch
  ];
})
