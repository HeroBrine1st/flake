# This is essentially nixpkgs nvidia module with xorg parts removed, and with hardware.graphics.enable = false.
#
# This module does not fully isolate nvidia from the rest of the system like IOMMU with virtual machine does: kernel driver is still loaded into host kernel.
# You better use official nixpkgs module because it has the same properties, and if you don't run gpu applications outside of containers,
# this even has the same security. This module simply prevents running gpu applications outside of containers,
# negligibly decreasing attack surface - a tired human should make more actions that simply run a binary.
#
# This module adds tty graphics implementation via nvidia driver, which is included into open kernel modules anyway.
# Tested with nvidia 575.64
{ pkgs, lib, config, options, modulesPath, ... }: let
  cfg = config.hardware.nvidia;

  # Various constants for easier code copying
  useOpenModules = true;
  nvidia_x11 = cfg.package;
  ibtSupport = useOpenModules || (nvidia_x11.ibtSupport or false);
in {
  options = {
    hardware.nvidia-container-toolkit.isolate = lib.mkEnableOption "isolation of proprietary userland drivers";
  };

  config = lib.mkIf (config.hardware.nvidia-container-toolkit.isolate && config.hardware.nvidia-container-toolkit.enable) (lib.mkMerge [
    {
      assertions = [
        {
          assertion = !config.virtualisation.docker.enableNvidia;
          message = "virtualisation.docker.enableNvidia exposes docker daemon to proprietary components. Use hardware.nvidia-container-toolkit.enable instead";
        }
        {
          assertion = !config.hardware.nvidia.datacenter.enable && !(lib.elem "nvidia" config.services.xserver.videoDrivers);
          message = "hardware.nvidia-container-toolkit.isolate reimplements nvidia module. Disable NixOS nvidia module";
        }
        {
          assertion = config.hardware.nvidia.open;
          message = "Only open nvidia drivers are supported. Set hardware.nvidia.open to true";
        }
        {
          assertion = !config.hardware.graphics.enable;
          message = "Isolated nvidia module is intended to be run on headless systems. Disable hardware.graphics";
        }
      ];
      hardware.graphics.enable = lib.mkForce false;
      hardware.nvidia-container-toolkit = {
        suppressNvidiaDriverAssertion = true; # reimplemented
        # reimplement hardware.graphics.enable
        # - https://github.com/NixOS/nixpkgs/pull/344174#discussion_r1800005937
        # - https://github.com/NixOS/nixpkgs/blob/4b1164c3215f018c4442463a27689d973cffd750/nixos/modules/hardware/video/nvidia.nix#L387
        mounts = let
          # 32-bit systems are explicitly unsupported TODO add check
          driversEnv = pkgs.buildEnv {
            name = "graphics-driver-with-isolated-nvidia";
            paths = [ nvidia_x11.out ];
          };
          prev = (lib.evalModules {
            modules = import (modulesPath + "/module-list.nix") ++ [
              {
                nixpkgs = { inherit (pkgs.stdenv) hostPlatform; };
              }
              {
                hardware.nvidia.package = nvidia_x11;
                hardware.nvidia-container-toolkit = {
                  enable = true;
                  suppressNvidiaDriverAssertion = true;
                };
              }
            ];
          }).config.hardware.nvidia-container-toolkit.mounts;
          # either way mkForce is required
        in lib.mkForce (
          (builtins.filter (x: x.containerPath != pkgs.addDriverRunpath.driverLink) prev)
          ++ [{
            hostPath = "${driversEnv}";
            containerPath = pkgs.addDriverRunpath.driverLink;
          }]
        );
      };
    }
    # taken from https://github.com/NixOS/nixpkgs/blob/4b1164c3215f018c4442463a27689d973cffd750/nixos/modules/hardware/video/nvidia.nix
    {
      boot = {
        blacklistedKernelModules = [
          "nouveau"
          "nvidiafb"
        ];

        kernelModules = [ "nvidia_uvm" ];
      };
      services.udev.extraRules = ''
        # Create /dev/nvidia-uvm when the nvidia-uvm module is loaded.
        KERNEL=="nvidia", RUN+="${pkgs.runtimeShell} -c 'mknod -m 666 /dev/nvidiactl c 195 255'"
        KERNEL=="nvidia", RUN+="${pkgs.runtimeShell} -c 'for i in $$(cat /proc/driver/nvidia/gpus/*/information | grep Minor | cut -d \  -f 4); do mknod -m 666 /dev/nvidia$${i} c 195 $${i}; done'"
        KERNEL=="nvidia_modeset", RUN+="${pkgs.runtimeShell} -c 'mknod -m 666 /dev/nvidia-modeset c 195 254'"
        KERNEL=="nvidia_uvm", RUN+="${pkgs.runtimeShell} -c 'mknod -m 666 /dev/nvidia-uvm c $$(grep nvidia-uvm /proc/devices | cut -d \  -f 1) 0'"
        KERNEL=="nvidia_uvm", RUN+="${pkgs.runtimeShell} -c 'mknod -m 666 /dev/nvidia-uvm-tools c $$(grep nvidia-uvm /proc/devices | cut -d \  -f 1) 1'"
      '';
    }
    {
      assertions = [
        {
          assertion = cfg.gsp.enable -> (cfg.package ? firmware);
          message = "This version of NVIDIA driver does not provide a GSP firmware.";
        }

        {
          assertion = useOpenModules -> (cfg.package ? open);
          message = "This version of NVIDIA driver does not provide a corresponding opensource kernel driver.";
        }

        {
          assertion = useOpenModules -> cfg.gsp.enable;
          message = "The GSP cannot be disabled when using the opensource kernel driver.";
        }
      ];

      systemd.services = lib.mkIf cfg.nvidiaPersistenced {
        "nvidia-persistenced" = {
          description = "NVIDIA Persistence Daemon";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "forking";
            Restart = "always";
            PIDFile = "/var/run/nvidia-persistenced/nvidia-persistenced.pid";
            ExecStart = "${lib.getExe nvidia_x11.persistenced} --verbose";
            ExecStopPost = "${pkgs.coreutils}/bin/rm -rf /var/run/nvidia-persistenced";
          };
        };
      };

      services.acpid.enable = true;
      hardware.firmware = lib.optional cfg.gsp.enable nvidia_x11.firmware;

      boot = {
        extraModulePackages = [ nvidia_x11.open ];
        # nvidia-uvm is required by CUDA applications.
        kernelModules = [
          "nvidia"
          # those two are for tty
          "nvidia_modeset"
          "nvidia_drm"
        ];

        # If requested enable modesetting via kernel parameters.
        kernelParams =
          lib.optional (cfg.modesetting.enable) "nvidia-drm.modeset=1"
          ++ lib.optional ((cfg.modesetting.enable) && lib.versionAtLeast nvidia_x11.version "545") "nvidia-drm.fbdev=1"
          ++ lib.optional useOpenModules "nvidia.NVreg_OpenRmEnableUnsupportedGpus=1"
          ++ lib.optional (config.boot.kernelPackages.kernel.kernelAtLeast "6.2" && !ibtSupport) "ibt=off";
      };
      services.udev.extraRules = lib.optionalString cfg.powerManagement.finegrained (
        lib.optionalString (lib.versionOlder config.boot.kernelPackages.kernel.version "5.5") ''
          # Remove NVIDIA USB xHCI Host Controller devices, if present
          ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{remove}="1"

          # Remove NVIDIA USB Type-C UCSI devices, if present
          ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{remove}="1"

          # Remove NVIDIA Audio devices, if present
          ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{remove}="1"
        ''
        + ''
          # Enable runtime PM for NVIDIA VGA/3D controller devices on driver bind
          ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
          ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"

          # Disable runtime PM for NVIDIA VGA/3D controller devices on driver unbind
          ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
          ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"
        ''
      );
    }
    {
      # Disable suspending due to absence of NVidia scripts
      # https://www.reddit.com/r/NixOS/comments/17motun/disable_sleep_suspend_hibernate_hybridsleep/
      systemd = {
        targets = {
          # Each possibly requires `unitConfig.DefaultDependencies = "no"` but idk why
          sleep.enable = false;
          suspend.enable = false;
          hibernate.enable = false;
          "hybrid-sleep".enable = false;
        };
      };
    }
  ]);
}