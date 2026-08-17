{ dockerTools, llama-cpp, pkgs, vllm }: {
  head = dockerTools.streamLayeredImage {
    name = llama-cpp.pname;
    tag = "${llama-cpp.version}-cuda-head_llama-swap-${pkgs.llama-swap.version}";
    contents = with pkgs; [
      llama-cpp llama-swap bash busybox
      vllm
      (pkgs.writeShellApplication {
        name = "llama-cpp.sh";
        runtimeInputs = [
          netcat gnugrep
        ];
        text = builtins.readFile ./llama-cpp.sh;
      })
    ];
  };
  worker = dockerTools.streamLayeredImage {
    name = llama-cpp.pname;
    tag = "${llama-cpp.version}-cuda-worker";
    contents = with pkgs; [ llama-cpp busybox ];
  };
}