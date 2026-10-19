{ pkgs, lib, flake, ip, config, ... }: let
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
      in lib.mkMerge [
        (let
          qwenFlashNext = { family, model, context ? 163840, kv ? "int8"}: {
            # manual actions:
            # add this to config:
            # "sampling": {"temperature": 1.0, "top_p": 0.95, "top_k": 20},
            # "reasoning_effort": "none",
            #  "fit_max_tokens": true,
            # also, https://www.reddit.com/r/LocalLLaMA/comments/1x8am0i/why_not_run_qwen_38_flash_next_with_the_full/
            cmd = lib.escapeShellArgs [
              "${config.virtualisation.docker.package}/bin/docker" "run" "--rm" "--name" "${family}-${model}"
              "--ulimit" "memlock=-1" "--device=nvidia.com/gpu=all"
              "--env-file" "${builtins.toFile "env" ''
                FAMILY=${family}
                MODEL=${model}
                CONTEXT=${builtins.toString context}
                KV=${kv}
                VISION=yes
                STRATA_ALLOWED_HOSTS=spark.herobrine1st.ru
                # qwen3.8 27b claimed thinking-only responses are omitted
                STRATA_KEEP_EMPTY_TURNS=1
              ''}"
              "-v" "${modelDir}/strata:/data"
              "-p" "127.0.0.1:\${PORT}:8080"
              "strata:latest" # built manually
            ];
            cmdStop = lib.escapeShellArgs [ "${config.virtualisation.docker.package}/bin/docker" "stop" "${family}-${model}" ];
            checkEndpoint = "/health";
            capabilities = {
              "in" = [ "text" "image" ];
              out = [ "text" ];
              tools = true;
              inherit context;
            };
            filters.setParamsByID = builtins.listToAttrs (builtins.map (reasoningStrength: {
              name = "\${MODEL_ID}-${reasoningStrength}";
              value = {
                reasoning.effort = reasoningStrength;
              };
            }) [ "low" "medium" "xhigh" ]);
          };
        in {
          "qwen3.8-flash-next:80b" = qwenFlashNext {
            family = "qwen";
            model = "IQ3_S";
          };
        })
        (let
          server = [ "${flake.pkgs.llama-cpp}/bin/llama-server" "--port" "\${PORT}" "--log-verbosity" "4" "--load-mode" "dio" ];
          caching = [ "--cache-ram" "16384" ];
          no_rpc = [ "--fit" "off" "--split-mode" "tensor" ];
          buildCommand = { extras ? [], cfg }: lib.escapeShellArgs (
            # presets are likely for multiple models, and I don't need router mode!
            builtins.concatLists ([ server ] ++ extras ++ lib.mapAttrsToList (name: value:
              (if value == false then [ "--no-${name}" ] else [ "--${name}" ]) ++
              (if builtins.isBool value then [] else [ value ])
            ))
          );
          reasoningStrengthFilters = strengths: builtins.listToAttrs (builtins.map (reasoningStrength: {
              name = "\${MODEL_ID}-${reasoningStrength}";
              value.chatTemplateParams = {
                enableThinking = true;
                inherit reasoningStrength;
              };
            }) strengths);
          reasoningFilters = {
            "\${MODEL_ID}-${reasoningStrength}".enableThinking = true;
          };
        in {
          "qwen3.8:27b" = let
            context = 163840;
          in {
            cmd = buildCommand {
              extras = [ caching no_rpc ];
              cfg = {
                model = "${modelDir}/Qwen3.8-27B-GSQ-RCO-IQ3_S-mtp.gguf";
                flash-attn = "on";
                cache-type-k = "q8_0";
                cache-type-v = "q6_0";
                ctx-size = context;
                swa-full = true;
                mmproj = "${modelDir}/Qwen3.8-27B-mmproj-F16.gguf";
                image-min-tokens = 1024;
                spec-type = "draft-mtp";
                spec-draft-n-min = 1;
                spec-draft-n-max = 3;
                chat-template-file = "${modelDir}/Qwen3.8-27B.jinja";
                reasoning = "off";
                reasoning-preserve = true;
                temp = 1.0;
                top-p = 0.95;
                top-k = 20;
                min-p = 0.0;
                presence-penalty = 0.0;
                repeat-penalty = 1.0;
              };
            };
            capabilities = {
              "in" = [ "text" "image" ];
              out = [ "text" ];
              tools = true;
              inherit context;
            };
            filters.setParamsByID = reasoningStrengthFilters [ "low" "medium" "xhigh" ];
          };
          "muse-glimmer:30b" = {
            cmd = buildCommand {
              extras = [ caching no_rpc ];
              cfg = {
                model = "${modelDir}/Muse-Glimmer-30B-UD-Q4_K_XL.gguf";
                flash-attn = "on";
                cache-type-k = "q8_0";
                cache-type-v = "q8_0";
                mmproj = "${modelDir}/Muse-Glimmer-30B-mmproj-kquant.gguf";
                mmproj-offload = false;
                spec-type = "draft-dflash";
                spec-draft-model = "${modelDir}/Muse-Glimmer-30B-dflash-kquant.gguf";
                spec-draft-n-max = 15;
                reasoning = "off";
              };
            };
            filters.setParamsByID = reasoningStrengthFilters [ "low" "medium" "high" "xhigh" ];
          };
          "gemma4:31b" = {
            cmd = buildCommand {
              cfg = {
                model = "${modelDir}/gemma-4-31B-it-qat-UD-Q4_K_XL.gguf";
                flash-attn = "on";
                cache-type-k = "q6_0";
                cache-type-v = "q5_0";
                mmproj = "${modelDir}/gemma-4-31B-it-qat-mmproj-BF16.gguf";
                mmproj-offload = false;
                ctx-size = 81920;
                chat-template-file = "${modelDir}/gemma-4.jinja";
                reasoning = "off";
                chat-template-kwargs = builtins.toJson { preserve_thinking = true; };
              };
            };
            filters.setParamsByID = reasoningFilters;
          };
          "gemma4:12b" = {
            cmd = buildCommand {
              cfg = {
                model = "${modelDir}/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf";
                flash-attn = "on";
                cache-type-k = "q6_0";
                cache-type-v = "q6_0";
                mmproj = "${modelDir}/gemma-4-12B-it-qat-mmproj-BF16.gguf";
                ctx-size = 262144;
                chat-template-file = "${modelDir}/gemma-4.jinja";
                reasoning = "off";
                chat-template-kwargs = builtins.toJson { preserve_thinking = true; };
              };
            };
            filters.setParamsByID = reasoningFilters;
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
        })
      ];
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

  systemd.services.llama-swap.serviceConfig.Group = "docker";
}
