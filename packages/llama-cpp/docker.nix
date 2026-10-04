{ dockerTools, llama-cpp, whisper-cpp, pkgs }: {
  head = dockerTools.streamLayeredImage {
    name = llama-cpp.pname;
    tag = "${llama-cpp.version}-cuda-head_whisper-cpp-${whisper-cpp.version}_llama-swap-${pkgs.llama-swap.version}";
    contents = with pkgs; [
      llama-swap
      llama-cpp bash busybox
      whisper-cpp
    ];
  };
  worker = dockerTools.streamLayeredImage {
    name = llama-cpp.pname;
    tag = "${llama-cpp.version}-cuda-worker";
    contents = with pkgs; [ llama-cpp busybox ];
  };
}