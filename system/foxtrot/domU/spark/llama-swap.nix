{ pkgs, lib, flake, ip, ... }: let
  modelDir = "/models";
  replaceKeys = replacements: attrs:
    lib.mapAttrs' (name: value: {
      name = replacements.${name} or name;
      value = if builtins.isAttrs value
        then replaceKeys replacements value
        else value;
    }) attrs;
in {
  services.llama-swap = {
    enable = true;
    openFirewall = true;
    listenAddress = ip;
    settings = replaceKeys {
      "chatTemplateParams" = "chat_template_kwargs";
      "reasoningStrength" = "reasoning_strength";
      "enableThinking" = "enable_thinking";
    } {
      healthCheckTimeout = 600;
      globalTTL = 1800;
      captureBuffer = 0;
      includeAliasesInList = true;
      models = let
        server = [ "${flake.pkgs.llama-cpp}/bin/llama-server" "--port" "\${PORT}" "--log-verbosity" "4" "--load-mode" "dio" ];
        caching = [ "--cache-ram" "2048" ]; # TODO 16384
        no_rpc = [ "--fit" "off" "--split-mode" "tensor" ];
      in {
        "qwen3.8:27b" = {
          cmd = lib.escapeShellArgs (server ++ caching ++ no_rpc ++ [
            "--model" "${modelDir}/Qwen3.8-27B-GSQ-RCO-IQ3_S-mtp.gguf"
            "--flash-attn" "on" "--cache-type-k" "q8_0" "--cache-type-v" "q6_0"
            "--ctx-size" "163840" "--swa-full"
            "--mmproj" "${modelDir}/Qwen3.8-27B-mmproj-F16.gguf" "--image-min-tokens" "1024"
            "--spec-type" "draft-mtp" "--spec-draft-n-max" "3" "--spec-draft-n-min" "1"
            "--chat-template-file" "${modelDir}/Qwen3.8-27B.jinja" "--reasoning" "off" "--reasoning-preserve"
            "--temp" "1.0" "--top-p" "0.95" "--top-k" "20" "--min-p" "0.0" "--presence-penalty" "0.0" "--repeat-penalty" "1.0"
          ]);
          capabilities = {
            "in" = [ "text" "image" ];
            out = [ "text" ];
            tools = true;
            context = 163840;
          };
          filters.setParamsByID = builtins.listToAttrs (builtins.map (reasoningStrength: {
            name = "\${MODEL_ID}-${reasoningStrength}";
            value.chatTemplateParams = {
              enableThinking = true;
              inherit reasoningStrength;
            };
          }) [ "low" "medium" "xhigh" ]);
        };
        "embeddinggemma2" = {
          cmd = lib.escapeShellArgs (server ++ [
            "--model" "${modelDir}/embeddinggemma-2-Q8_0.gguf"
            "--mmproj" "${modelDir}/embeddinggemma-2-mmproj-Q8_0.gguf"
            "--embedding"
            "-b" "8192" "-ub" "8192" "--parallel" "4"
            "--device" "none"
          ]);
        };
        "datalab-to/surya-ocr-2" = {
          cmd = lib.escapeShellArgs (server ++ [
            "--model" "${modelDir}/surya-2.gguf"
            "--mmproj" "${modelDir}/surya-2-mmproj.gguf"
            "--flash-attn" "on"
            "--predict" "8192"
          ]);
        };
      };
      groups = {
        embedding = {
          swap = false;
          persistent = true;
          exclusive = false;
          members = [
            "embeddinggemma2"
          ];
        };
      };
    };
  };
}