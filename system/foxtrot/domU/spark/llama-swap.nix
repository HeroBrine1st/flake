{ pkgs, lib, flake, ip, config, ... }: let
  modelDir = "/models";
  models = {
    "whisper-large-v3-turbo-q5_0" = {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin";
      size = 574041195;
    };
    "surya-2.5-q8_0" = {
      url = "https://huggingface.co/datalab-to/surya-ocr-2.5-gguf/resolve/main/surya-2.5-Q8_0.gguf";
      size = 628680096;
    };
    "surya-2.5-mmproj" = {
      url = "https://huggingface.co/datalab-to/surya-ocr-2.5-gguf/resolve/main/surya-2.5-mmproj.gguf";
      size = 207345920;
    };
    "surya-2.5-chat-template" = {
      url = "https://huggingface.co/datalab-to/surya-ocr-2.5-gguf/resolve/main/chat_template.jinja";
      fileName = "surya-2.5.jinja";
      size = 2872;
    };
  };
  fileName = name:
    models.${name}.fileName
    or (lib.last (lib.splitString "/" (builtins.head (lib.splitString "?" models.${name}.url))));
  pathByName = name: "${modelDir}/${fileName name}";

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
    validateConfigFile = false; # because it tries to write into store.path!
    settings = replaceKeys {
      "chatTemplateParams" = "chat_template_kwargs";
      "reasoningStrength" = "reasoning_strength";
      "enableThinking" = "enable_thinking";
    } {
      healthCheckTimeout = 600;
      globalTTL = 1800;
      captureBuffer = 0;
      includeAliasesInList = true;
      store.path = "/var/lib/llama-swap/llama-swap.sqlite";
      upstream.ignorePaths = [
        ".*\.(js|json|css|png|gif|jpg|jpeg|ico|txt)$"
        # comfyui
        "^/ws(/|$)"
        "^/api/jobs$"
        # strata
        "^/metrics(/|$)"
      ];
      models = lib.mkMerge [
        (let
          qwenFlashNext = { family, model, context ? 163840, kv ? "int8", extras ? {} }: {
            # manual actions:
            # add this to config:
            # "sampling": {"temperature": 1.0, "top_p": 0.95, "top_k": 20},
            # "reasoning_effort": "none",
            # "fit_max_tokens": true,
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
                STRATA_KV_GROW=1
              ''}"
              "-v" "${modelDir}/strata:/data"
              "-p" "127.0.0.1:\${PORT}:8080"
              "strata:0.1.45" # built manually
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
          } // extras;
        in {
          "qwen3.8-flash-next:80b" = qwenFlashNext {
            family = "qwen";
            model = "IQ3_S";
            extras = {
              ttl = 0;
            };
          };
        })
        (let
          server = [ "${flake.pkgs.llama-cpp}/bin/llama-server" "--port" "\${PORT}" "--log-verbosity" "4" "--load-mode" "dio" ];
          caching = [ "--cache-ram" "16384" ];
          no_rpc = [ "--fit" "off" "--split-mode" "tensor" ];
          buildCommand = { extras ? [], cfg }: lib.escapeShellArgs (
            # presets are likely for multiple models, and I don't need router mode!
            builtins.concatLists ([ server ] ++ extras ++ (lib.mapAttrsToList (name: value:
              (if value == false then [ "--no-${name}" ] else [ "--${name}" ]) ++
              (if builtins.isBool value then [] else [ value ])
            ) cfg))
          );
          reasoningStrengthFilters = strengths: builtins.listToAttrs (builtins.map (reasoningStrength: {
              name = "\${MODEL_ID}-${reasoningStrength}";
              value.chatTemplateParams = {
                enableThinking = true;
                inherit reasoningStrength;
              };
            }) strengths);
          reasoningFilters = {
            "\${MODEL_ID}-reasoning".enableThinking = true;
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
              extras = [ caching no_rpc ];
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
                chat-template-kwargs = builtins.toJSON { preserve_thinking = true; };
              };
            };
            filters.setParamsByID = reasoningFilters;
          };
          "gemma4:12b" = {
            cmd = buildCommand {
              extras = [ caching no_rpc ];
              cfg = {
                model = "${modelDir}/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf";
                flash-attn = "on";
                cache-type-k = "q6_0";
                cache-type-v = "q6_0";
                mmproj = "${modelDir}/gemma-4-12B-it-qat-mmproj-BF16.gguf";
                ctx-size = 262144;
                chat-template-file = "${modelDir}/gemma-4.jinja";
                reasoning = "off";
                chat-template-kwargs = builtins.toJSON { preserve_thinking = true; };
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
          "datalab-to/surya-ocr-2.5" = {
            cmd = lib.escapeShellArgs (server ++ [
              "--model" (pathByName "surya-2.5-q8_0")
              "--mmproj" (pathByName "surya-2.5-mmproj")
              "--chat-template-file" (pathByName "surya-2.5-chat-template")
              "--flash-attn" "on"
              "--predict" "8192"
            ]);
          };
        })
        {
          "whisper:large-v3-turbo" = {
            checkEndpoint = "/v1/audio/transcriptions/health";
            capabilities = {
              "in" = [ "audio" ];
              out = [ "text" ];
            };
            cmd = lib.escapeShellArgs [
              "${flake.pkgs.whisper-cpp}/bin/whisper-server"
              "--host" "127.0.0.1"
              "--port" "\${PORT}"
              "--model" (pathByName "whisper-large-v3-turbo-q5_0")
              "--language" "auto"
              "--no-timestamps"
              "--convert"
              "--tmp-dir" "/tmp"
              "--request-path" "/v1/audio/transcriptions"
              "--inference-path" ""
            ];
          };
        }
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

  systemd.services.llama-swap.serviceConfig = {
    Group = "docker";
    StateDirectory = "llama-swap";
    RuntimeDirectory = "llama-swap";
  };

  systemd.services.llama-swap-models = {
    description = "Fetch llama-swap model files into ${modelDir}";
    wantedBy = [ "llama-swap.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.coreutils pkgs.curl ];
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = 30;
      Umask = "0022";
    };
    script = ''
      fetch() {
        local url="$1" path="$2" want="$3" got
        mkdir -p "$(dirname -- "$path")"
        got=$(stat -c %s -- "$path" 2>/dev/null || echo 0)
        if [ "$got" -eq "$want" ]; then
          echo "$path: complete ($got bytes)"
          return 0
        fi
        echo "$path: $got/$want bytes, fetching"
        curl --fail --location --continue-at - --retry 3 --retry-all-errors \
          --connect-timeout 10 --no-progress-meter --show-error --output "$path" "$url" || return 1
        got=$(stat -c %s -- "$path" 2>/dev/null || echo 0)
        if [ "$got" -ne "$want" ]; then
          echo "$path: still $got/$want bytes"
          return 1
        fi
        echo "$path: complete ($got bytes)"
      }

      status=0
      ${lib.concatMapStringsSep "\n" (name:
        ''fetch "${models.${name}.url}" "${pathByName name}" "${toString models.${name}.size}" || status=1''
      ) (builtins.attrNames models)}
      exit $status
    '';
  };

  services.impermanence.extraDirectories = [
    "/var/lib/private/llama-swap"
  ];
}
