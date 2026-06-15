{ llama-cpp, lib, fetchFromGitHub }: (llama-cpp.override {
  rpcSupport = true;
  cudaSupport = true;
}).overrideAttrs (final: old: {
  pname = "beellama-cpp";
  version = "000301"; # LLAMA_BUILD_NUMBER is an integer
  src = fetchFromGitHub {
    owner = "Anbeeld";
    repo = "beellama.cpp";
    rev = "v${final.version}";
    hash = "sha256-sKoFROgpOE8bsFTAe34suJ5j9DWln5wlBxR0MVuhKgQ=";
  };
  npmDepsHash = "sha256-1iM0LGeI9e+gZEHk46lkBe51DxIhiimfAm9o3Z3m9Ik=";
  cmakeFlags = old.cmakeFlags ++ [
    # https://github.com/Anbeeld/beellama.cpp/blob/main/docs/quickstart-qwen36-dflash.md
    # required for TurboQuant and TCQ cache types
    (lib.cmakeBool "GGML_CUDA_FA_ALL_QUANTS" true)
    (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "86;75")
  ];
  patches = (old.patches or []) ++ [
    # This one is embedded in beellama.cpp
    #(builtins.toFile "consider-mmproj-offload-in-vram-reservation.patch" ''
    #  diff --git a/tools/server/server-context.cpp b/tools/server/server-context.cpp
    #  index bfe3443c..800da19b 100644
    #  --- a/tools/server/server-context.cpp
    #  +++ b/tools/server/server-context.cpp
    #  @@ -769,7 +769,7 @@ private:
    #           }
    #
    #           // optionally get the memory usage of mmproj
    #  -        if (has_mmproj && params_base.fit_params) {
    #  +        if (has_mmproj && params_base.fit_params && params_base.mmproj_use_gpu) {
    #               auto mmproj_mem = mtmd_get_memory_usage(mmproj_path.c_str(), mparams);
    #               if (!mmproj_mem.empty()) {
    #                   size_t total = 0;
    #
    #'')
  ];
})