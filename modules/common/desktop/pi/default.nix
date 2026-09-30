{ pkgs, ... }:
let
  subagent = "${pkgs.pi-coding-agent}/lib/node_modules/pi-monorepo/examples/extensions/subagent";
in
{
  environment = {
    systemPackages = with pkgs; [
      pi-coding-agent
    ];

    variables = {
      # ~ is expanded by Pi
      PI_CODING_AGENT_DIR = "~/.jetbrains/pi/agent";
      PI_CODING_AGENT_SESSION_DIR = "~/.jetbrains/pi/sessions";
      PI_OFFLINE = "1";
      PI_TELEMETRY = "0";
    };
  };

  home-manager.users.herobrine1st.home.file = builtins.mapAttrs (_: v: v // { force = true; }) {
    ".jetbrains/pi/agent/settings.json".text = builtins.toJSON {
      theme = "dark";
      defaultProvider = "llama-swap";
      defaultModel = "qwen3.8:27b";
      defaultThinkingLevel = "xhigh";
      markdown.mermaid = "streaming";
      hideThinkingBlock = false;
      steeringMode = "all";
      followUpMode = "all";
      showCacheMissNotices = true;

      extensions = [
        ./extensions/prefix-compaction/index.ts
      ];
      packages = [
        "${subagent}/index.ts"
      ];
    };

    ".jetbrains/pi/agent/models.json".text = builtins.toJSON {
      providers."llama-swap" = {
        baseUrl = "https://spark.herobrine1st.ru/v1";
        api = "openai-completions";
        apiKey = "dummy";
        compat = {
          thinkingFormat = "chat-template";
          chatTemplateKwargs = {
            enable_thinking = { "$var" = "thinking.enabled"; };
            preserve_thinking = true;
            reasoning_effort = { "$var" = "thinking.effort"; omitWhenOff = true; };
          };
        };
        models = [
          {
            id = "qwen3.8:27b";
            name = "Qwen 3.8 27B";
            input = [ "text" "image" ];
            contextWindow = 163840;
            maxTokens = 65536;
            reasoning = true;
            thinkingLevelMap = {
              minimal = null;
              high = null;
              xhigh = "xhigh";
            };
          }
        ];
      };
    };

    ".jetbrains/pi/agent/keybindings.json".text = builtins.toJSON {
      "tui.input.newLine" = [ "shift+enter" "ctrl+j" "alt+enter" ];
      "app.message.followUp" = "alt+q";
    };


    ".jetbrains/pi/agent/agents/scout.md".source = "${subagent}/agents/scout.md";
    ".jetbrains/pi/agent/agents/planner.md".source = "${subagent}/agents/planner.md";
    ".jetbrains/pi/agent/agents/reviewer.md".source = "${subagent}/agents/reviewer.md";
    ".jetbrains/pi/agent/agents/worker.md".source = "${subagent}/agents/worker.md";
  };
}
