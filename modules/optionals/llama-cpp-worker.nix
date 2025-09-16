# Clearly a copy of nixpkgs llama-cpp module
{ custom-pkgs, config, lib, ... }: let
  cfg = config.services.llama-cpp.worker;
in {
  options.services.llama-cpp.worker = {
    enable = lib.mkEnableOption "LLaMA C++ RPC worker";
    package = lib.mkPackageOption custom-pkgs "llama-cpp" {};
    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "IP address the LLaMA C++ RPC worker listens on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 50052;
      description = "Listen port for LLaMA C++ RPC worker.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open ports in the firewall for LLaMA C++ RPC worker.";
    };

    cache.enable = lib.mkEnableOption "tensor caching";
  };
  config = lib.mkIf cfg.enable {
    systemd.services = {
      "llama-cpp-worker" = {
        description = "LLaMA C++ RPC worker";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        environment = {
          LLAMA_CACHE = "/var/lib/llama-rpc-worker";
        };

        serviceConfig = {
          Type = "idle";
          KillSignal = "SIGINT";
          ExecStart = "${cfg.package}/bin/llama-rpc-server --host ${cfg.host} --port ${builtins.toString cfg.port} ${lib.optionalString cfg.cache.enable "-c"}";
          Restart = "on-failure";
          RestartSec = 300;

          StateDirectory = "llama-rpc-worker";

          # for GPU acceleration
          PrivateDevices = false;
          DeviceAllow = [ # Copied from ollama
            # CUDA
            # https://docs.nvidia.com/dgx/pdf/dgx-os-5-user-guide.pdf
            "char-nvidiactl"
            "char-nvidia-caps"
            "char-nvidia-frontend"
            "char-nvidia-uvm"
            # ROCm
            "char-drm"
            "char-fb"
            "char-kfd"
            # WSL (Windows Subsystem for Linux)
            "/dev/dxg"
          ];

          # hardening
          DynamicUser = true;
          CapabilityBoundingSet = "";
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          NoNewPrivileges = true;
          PrivateMounts = true;
          PrivateTmp = true;
          PrivateUsers = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "strict";
          MemoryDenyWriteExecute = true;
          LockPersonality = true;
          RemoveIPC = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
          SystemCallErrorNumber = "EPERM";
          ProtectProc = "invisible";
          ProtectHostname = true;
          ProcSubset = "pid";
        };
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}