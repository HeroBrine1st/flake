# audio.cpp for CUDA — fully in-tree (no IFD: we do not evaluate nix files out of the fetched tarball).
#
# This is an adapted copy of upstream's own .devops/nix/package.nix (MIT, 0xShug0/audio.cpp v0.9.2),
# with `src = lib.cleanSource ../..` replaced by a fetchFromGitHub and the ROCm/Vulkan/Metal branches
# dropped (this flake only wants the CUDA build).
#
# Builds: audiocpp_cli, audiocpp_server, audiocpp_gguf, audiocpp_model_manager + model_specs data.
# -DENGINE_ENABLE_CUDA=ON selects ggml's CUDA backend (upstream requires CUDAToolkit >= 12).
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  openssl,
  python3,
  cudaPackages,
  autoAddDriverRunpath,
  cudaSupport ? true,
  # Turing (RTX 2070 in this fleet) + Ampere; same pair as our llama-cpp package
  cudaArchitectures ? [ "75" "86" ],
  # model selection: if non-empty, only these model targets are built (CMakeLists AUDIOCPP_MODEL_SET)
  models ? [ ],
}:
let
  python-scripts = python3.withPackages (ps: with ps; [
    ps.torch
    ps.safetensors
    ps.pyyaml
    ps.numpy
  ]);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "audio-cpp";
  version = "0.9.2";

  src = fetchFromGitHub {
    owner = "0xShug0";
    repo = "audio.cpp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-2Rgy6WbHVZKlHqQYTc2vg9iRRYPYlMY2F5511bcZ5BE=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
    autoAddDriverRunpath
  ];

  buildInputs = [
    python-scripts
    openssl # native model manager (HTTPS downloads)
  ]
  ++ lib.optionals cudaSupport [
    # upstream uses cudaPackages.cudatoolkit (= the big merged unfree package in this nixpkgs);
    # the CMake `find_package(CUDAToolkit)` is satisfied by the granular packages plus
    # the cuda setup hook's CUDAToolkit_ROOT, same as our strata package does.
    # engine_runtime links CUDA::cufft (CMakeLists.txt:2698), CUDA::cublas - add more
    # granular packages here if CMake asks for more targets.
    cudaPackages.cccl
    cudaPackages.cuda_cudart
    cudaPackages.libcublas
    cudaPackages.libcufft
  ];

  cmakeFlags = [
    (lib.cmakeBool "ENGINE_ENABLE_NATIVE_CPU" true)
    (lib.cmakeBool "ENGINE_ENABLE_LLAMAFILE" true)
    (lib.cmakeBool "AUDIOCPP_BUILD_NATIVE_MODEL_MANAGER" true)
    (lib.cmakeBool "AUDIOCPP_USE_SYSTEM_OPENSSL" true)
    (lib.cmakeBool "ENGINE_ENABLE_CUDA" true)
    # ggml's CUDA arch list (upstream defaults to everything when unset; keep it explicit)
    (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" (lib.concatStringsSep ";" cudaArchitectures))
  ]
  ++ lib.optionals (models != [ ]) [
    (lib.cmakeFeature "AUDIOCPP_MODEL_SET" "custom")
    (lib.cmakeFeature "AUDIOCPP_MODELS" (lib.concatStringsSep "," models))
  ]
  ++ lib.optionals (models == [ ]) [
    (lib.cmakeFeature "AUDIOCPP_MODEL_SET" "full")
  ];

  # upstream builds RelWithDebInfo; keep that (their CI and reports use it)
  cmakeBuildType = "RelWithDebInfo";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    # Copy the built C++ executables directly from the bin directory
    cp bin/audiocpp_cli bin/audiocpp_server bin/audiocpp_gguf $out/bin/
    cp bin/audiocpp_model_manager $out/bin/

    # Keep the supported Python v2 manager available during migration without
    # overwriting the native audiocpp_model_manager executable copied above.
    install -Dm755 $src/tools/model_manager_v2.py $out/bin/audiocpp_model_manager_v2.py
    cp -R $src/model_specs $out/model_specs

    # Patch the shebang to use our python environment with torch/safetensors/pyyaml
    patchShebangs $out/bin/audiocpp_model_manager_v2.py

    runHook postInstall
  '';

  meta = {
    description = "A high-performance C++ audio inference framework (CUDA)";
    homepage = "https://github.com/0xShug0/audio.cpp";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "audiocpp_cli";
  };
})
