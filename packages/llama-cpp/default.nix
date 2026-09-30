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
  
  #version = let v = "10517"; in assert lib.versionOlder old.version v; v;
  #src = old.src.override {
  #  tag = "b${final.version}";
  #  hash = "sha256-heMmF0gQNPdxRLxwU/JB/9vtAoZ66EJPllY8ans/5Cw=";
  #};

  version = "0.5.0";
  src = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = "v${final.version}";
    hash = "sha256-MtSVt0qM8I0MeMzVxT7+nVkhQ7ysMS4/kbk/DxzTI2A=";
  };
  npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
  buildInputs = old.buildInputs ++ [
    cudaPackages.nccl
  ];

  #postInstall = builtins.replaceStrings ["cp bin/rpc-server $out/bin/llama-rpc-server"] [""] old.postInstall;
  #npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
  cmakeFlags = old.cmakeFlags ++ [
    # https://github.com/Anbeeld/beellama.cpp/blob/main/docs/quickstart-qwen36-dflash.md
    # required for TurboQuant and TCQ cache types
    # and possibly for q6.patch
    (lib.cmakeFeature "GGML_CUDA_FA_QUANTS" "all")
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
