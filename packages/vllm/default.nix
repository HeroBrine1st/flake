{ python313Packages, fetchFromGitHub }:

let
  qwen38-27b-rtx3090 = fetchFromGitHub {
    owner = "syv-ai";
    repo = "qwen38-27b-rtx3090";
    rev = "9850338a4c11bbc2130240ef7f050713a6424048";
    hash = "sha256-MtXneEJWmNOF8pKJNZSHOXVcApuRdicbarkwOkDXzS0=";
  };
in
python313Packages.vllm.overridePythonAttrs {
  patches = [
    "${qwen38-27b-rtx3090}/patches/add_qwen38_max_support.patch"
    "${qwen38-27b-rtx3090}/patches/0001-fix_moe_chunk_size.patch"
    "${qwen38-27b-rtx3090}/patches/0002-fix_rocm_build.patch"
    "${qwen38-27b-rtx3090}/patches/0003-fix_deepgemm_hip_build.patch"
    "${qwen38-27b-rtx3090}/patches/0004-disable-mla-due-to-uncompilable-deepgemm.patch"
  ];
}
