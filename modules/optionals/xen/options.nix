{ lib, modulesPath, pkgs, utils, ... }@host: let
  nix-store-disk = "xvdz"; # HVM reserves some first disks to be emulated; everything else is PV
  nixStoreFilesystemLabel = "nix-store";
in {
  options = {
    # see http://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/nixos-containers.nix
    virtualisation.xen = {
      machines = lib.mkOption {
        default = {};
        type = lib.types.attrsOf (lib.types.submodule ({ name, ... }@machine: {
          options = {
            modules = lib.mkOption {
              type = lib.types.listOf (lib.types.oneOf [
                lib.types.path
                lib.types.attrs
                (lib.types.functionTo lib.types.attrs)
              ]);
            };
            type = lib.mkOption {
              type = lib.types.enum [ "hvm" "pv" "pvh" ];
              default = "pvh";
            };
            networking.bridges.xenbr0 = {
              ip = lib.mkOption {
                type = lib.types.str;
              };
              mac = lib.mkOption {
                type = lib.types.str;
              };
            };
            extraXenlight = lib.mkOption {
              description = "Additional xl.cfg content";
              type = lib.types.lines;
              default = "";
            };
            specialArgs = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = {};
            };

            definition = lib.mkOption {
              description = "Generated xl.cfg file";
              type = lib.types.package;
              readOnly = true;
              internal = true;
            };

            system = lib.mkOption {
              description = "Module evaluation result";

              readOnly = true;
            };

            disks = lib.mkOption {
              type = lib.types.attrsOf (lib.types.submodule ({ name, ... }@disk: {
                options = {
                  target = lib.mkOption {
                    type = lib.types.pathWith {}; # can be non-absolute, can be in store
                  };
                  format = lib.mkOption {
                    type = lib.types.enum [ "raw" "qcow" "qcow2" "vhd" "qed" ];
                    default = "raw";
                  };
                  vdev = lib.mkOption {
                    type = lib.types.strMatching ''(hd|xvd|sd).+'';
                    default = disk.name;
                  };
                  readOnly = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                  };
                  spec = lib.mkOption {
                    type = lib.types.str;
                    internal = true;
                    readOnly = true;
                  };
                };
                config = let
                  cfg = disk.config;
                  access = if cfg.readOnly then "ro" else "rw";
                in {
                  spec = "${cfg.target},${cfg.format},${cfg.vdev},${access}";
                };
              }));
            };
          };
          config = let
            guest = import "${modulesPath}/../lib/eval-config.nix" {
              modules = [
                (import ./guest.nix {
                  inherit host nix-store-disk machine;
                })
                (modulesPath + "/virtualisation/xen-domU.nix")
              ] ++ machine.config.modules;
              prefix = [ "virtualisation" "xen" "machines" machine.name "modules" "*" ];
              specialArgs = host.specialArgs // machine.config.specialArgs;
              system = null;
            };
            gconfig = guest.config;
          in {
            system = guest;
            disks."${nix-store-disk}" = {
              target = let
                closure = pkgs.closureInfo { rootPaths = [ gconfig.system.build.toplevel ]; };
              # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/qemu-vm.nix
              in pkgs.runCommand "${machine.name}-store.img" {
                __structuredAttrs = true;
                unsafeDiscardReferences.out = true;
              } ''
                echo -n "${gconfig.system.build.toplevel}" > toplevel
                ${pkgs.gnutar}/bin/tar --create \
                  --absolute-names \
                  ${lib.optionalString (!gconfig.nix.enable) ''
                    --transform 'flags=rSh;s|/nix/store/||' \
                    --transform 'flags=rSh;s|~nix~case~hack~[[:digit:]]\+||g' \
                  ''} \
                  --verbatim-files-from \
                  --files-from=${closure}/store-paths \
                  ${lib.optionalString gconfig.nix.enable ''
                    --add-file toplevel \
                    -C ${closure} --add-file store-paths --add-file registration \
                  ''} \
                | ${pkgs.erofs-utils}/bin/mkfs.erofs \
                  --quiet \
                  --force-uid=0 \
                  --force-gid=0 \
                  -L ${nixStoreFilesystemLabel} \
                  -U eb176051-bd15-49b7-9e6b-462e0b467019 \
                  -T 0 \
                  --hard-dereference \
                  --tar=f \
                  $out
              '';
              readOnly = true;
              format = "raw";
            };
            definition = pkgs.runCommand "${machine.name}-xl.json" {
              json = builtins.toJSON {
                core = ''
                  name="${machine.name}"
                  type="${machine.config.type}"

                  kernel="${gconfig.boot.kernelPackages.kernel}/${gconfig.system.boot.loader.kernelFile}"
                  ramdisk="${gconfig.system.build.initialRamdisk}/${gconfig.system.boot.loader.initrdFile}"
                  disk=[ ${lib.concatMapStringsSep ", " (x: ''"${x.spec}"'') (lib.attrValues machine.config.disks) } ]

                  vif=[ ${lib.concatMapAttrsStringSep ", " (bridge: bridgeCfg: "'mac=${bridgeCfg.mac},bridge=${bridge}'") machine.config.networking.bridges} ]
                '';
                inherit (machine.config) extraXenlight;
              };

              # what happens in VM stays in VM, base64 is used to trick scanner
              base64 = ''
                cmdline='init=${gconfig.system.build.toplevel}/init ${toString gconfig.boot.kernelParams}'
              '';

              passAsFile = [ "json" "base64" ];
            } ''
              ${pkgs.jq}/bin/jq --arg base64 $(${pkgs.coreutils}/bin/base64 -w 0 $base64Path) \
                '.base64 = $base64' "$jsonPath" > $out
            '';
          };
        }));
      };
      # partial forward compatibility with multiple bridges
      networking.bridges.xenbr0 = {
        enable = lib.mkEnableOption "xenbr0 interface" // { default = false; };
        address = lib.mkOption {
          type = lib.types.str;
        };
        prefixLength = lib.mkOption {
          type = lib.types.ints.between 0 32;
        };
        gateway = lib.mkOption {
          description = "Host address";
          type = lib.types.str;
        };
        dhcp.pool = lib.mkOption {
          example = "10.0.0.10-10.0.0.254";
          type = lib.types.str;
        };
        dhcp.dns = lib.mkOption {
          type = lib.types.commas;
          default = "1.1.1.1, 1.0.0.1";
        };
        dhcp.reservations = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule {
            options = {
              mac = lib.mkOption {
                type = lib.types.str;
              };
              ip = lib.mkOption {
                type = lib.types.str;
              };
            };
          });
          default = [];
        };
      };
    };
  };
}