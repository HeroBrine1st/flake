{ llama-cpp, lib, fetchFromGitHub, cudaPackages, npmHooks }: (llama-cpp.override {
  rpcSupport = true;
  cudaSupport = true;
}).overrideAttrs (final: old: {
  version = "11557";
  src = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = "b11557";
    hash = "sha256-kV7y1i5HWdGR6oBIxmiB+L/FgiJOKURdX/N5nznkMg4=";
  };

  # disable frontend
  npmDeps = null;
  nativeBuildInputs = builtins.filter (x: x != npmHooks.npmConfigHook) old.nativeBuildInputs;
  preConfigure = builtins.replaceStrings [ "npm run build" ] [ "" ] old.preConfigure;

  buildInputs = old.buildInputs ++ [
    cudaPackages.nccl
  ];

  cmakeFlags = old.cmakeFlags ++ [
    # https://github.com/Anbeeld/beellama.cpp/blob/main/docs/quickstart-qwen36-dflash.md
    # required for TurboQuant and TCQ cache types
    # and possibly for q6.patch
    (lib.cmakeFeature "GGML_CUDA_FA_QUANTS" "all")
    (lib.cmakeBool "GGML_CUDA_NCCL" true)
    (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "86;75")
    #(lib.cmakeFeature "LLAMA_BUILD_NUMBER" "000301") # it is an integer
  ];
  patches = [ # TODO: (old.patches or []) - https://github.com/ggml-org/llama.cpp/pull/30034 is included while it's in b11557 already
    # This one is embedded in beellama.cpp
    ./consider-mmproj-offload-in-vram-reservation.patch
    ./q6.patch
  ];
})
