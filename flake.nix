{
  description = "NixOS configuration";

  inputs = {
    pkgs-unstable.url = "nixpkgs/nixos-unstable-small";
    pkgs-stable.url = "nixpkgs/nixos-26.05-small";
    pkgs-bdfr.url = "nixpkgs/59b1aef59071cae6e87859dc65de973d2cc595c0"; # pinned
    pkgs-krita.url = "nixpkgs/5c21abf2abb5bcbbb8d486d1fc32305fb03b0414"; # pinned
    pkgs-jetbrains-oss.url = "nixpkgs/c1ca0f308953171c1cdbfd5a773b09cad6fb32d3"; # PR https://github.com/NixOS/nixpkgs/pull/552610
    nixos-rk3588.url = "github:HeroBrine1st/nixos-rk3588?rev=0b8b677e400fe178e46e0f04175ac2b9b6441b82"; # pinned
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "pkgs-unstable";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "pkgs-unstable";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs = {
        nixpkgs.follows = "pkgs-unstable";
        home-manager.follows = "home-manager";
      };
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "pkgs-unstable";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "pkgs-unstable";
    };
    ags = {
      # ags is broken on at least e5e2efaf2e05e077190cfddabf5b827edae5ef8b
      # ags bundle requires astal/gtk3/jsx-runtime on gtk4 projects, including both derivations listed in example and https://aylur.github.io/ags/guide/nix.html
      # no packages including astal3, astal4 and agsFull provide it
      # It was resolved on Arch Linux by using older ags: https://github.com/Jas-SinghFSU/HyprPanel/issues/1033#issuecomment-3031248116
      # Also it looks like ags v3 is released? https://github.com/Aylur/ags/issues/716
      url = "github:aylur/ags?rev=3ed9737bdbc8fc7a7c7ceef2165c9109f336bff6";
      inputs.nixpkgs.follows = "pkgs-unstable";
    };
    cloudflare-ips-v4 = {
      url = "https://www.cloudflare.com/ips-v4";
      flake = false;
    };
    cloudflare-ips-v6 = {
      url = "https://www.cloudflare.com/ips-v6";
      flake = false;
    };
    letta-code = {
      url = "github:letta-ai/letta-code/v0.33.2";
      inputs.nixpkgs.follows = "pkgs-unstable";
    };
  };

  outputs = { self, pkgs-unstable, pkgs-stable, nixos-rk3588, home-manager, disko, impermanence, lanzaboote, fenix, pkgs-bdfr, ags, ... }@inputs: let
    lib = pkgs-unstable.lib;
    forAllSystems = f: lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: f system);
    commonNixpkgsConfig = {
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
        "nvidia-x11" "nvidia-settings" "nvidia-kernel-modules" #"nvidia-persistenced"

        # common/desktop
        "android-studio"
        "rust-rover"
        "webstorm"
        "clion"
        "steam" "steam-original" "steam-run" "steam-unwrapped"
        "osu-lazer-bin"
        "veracrypt"
        "code" "vscode"
        "winbox"
      ];
    };
  in {
    nixosModules = {
      optionals = ./modules/optionals; # "optionals" means that they require an option to be enabled
      basic = ./modules/common;
      includeSource = ./modules/common/include-source.nix;
      desktop = ./modules/common/desktop;
      development = ./modules/common/development;
      hyprland = ./modules/common/desktop/hyprland;
      xen.domain = {
        onBtrfs = import ./modules/common/xen/btrfs.nix;
      };
    } // lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
      builtins.mapAttrs
      (_: nixpkgs: {
        # note: readOnlyPkgs source must match lib source (excludes module)
        imports = [ nixpkgs.nixosModules.readOnlyPkgs ];
        config.nixpkgs.pkgs = import nixpkgs {
          inherit system;
          config = commonNixpkgsConfig;
        };
      })
      {
        onUnstablePkgs = pkgs-unstable;
        onStablePkgs = pkgs-stable;
      }
    );
    legacyPackages = forAllSystems (system: import ./packages (inputs // {
      inherit system;
    }));
    nixosConfigurations = let
      commonSpecialArgs = system: {
        assets = ./assets;
        systems = import ./systems.nix;
        flake = self // {
          pkgs = self.legacyPackages."${system}";
        };
        cloudflare-ips = (lib.splitString "\n" (builtins.readFile inputs.cloudflare-ips-v4))
                      ++ (lib.splitString "\n" (builtins.readFile inputs.cloudflare-ips-v6));
      };
    in {
      alfa = let
        inherit (nixos-rk3588.inputs) nixpkgs; # pinning nixpkgs so that kernel is not rebuilt due to system update
        system = "aarch64-linux";
      in pkgs-stable.lib.nixosSystem {
        specialArgs = {
          rk3588 = {
            inherit nixpkgs;
            pkgsKernel = import nixpkgs {
              localSystem = "x86_64-linux";
              crossSystem = "aarch64-linux";
            };
          };
        } // commonSpecialArgs system;

        modules = [
          nixos-rk3588.nixosModules.orangepi5.core
          impermanence.nixosModules.impermanence
          self.nixosModules.${system}.onStablePkgs
          self.nixosModules.optionals
          self.nixosModules.basic
          self.nixosModules.includeSource

          ./system/alfa
        ];
      };
      DESKTOP-IJK2GUG = let
        system = "x86_64-linux";
      in pkgs-unstable.lib.nixosSystem {
        specialArgs = commonSpecialArgs system;
        modules = [
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
          self.nixosModules.${system}.onUnstablePkgs
          self.nixosModules.optionals
          self.nixosModules.basic
          self.nixosModules.includeSource
          self.nixosModules.desktop
          self.nixosModules.development

          ./system/pc
        ];
      };
      MOBILE-DCV5AQD = let
        system = "x86_64-linux";
      in pkgs-unstable.lib.nixosSystem {
        specialArgs = commonSpecialArgs system;
        modules = [
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
          self.nixosModules.${system}.onUnstablePkgs
          self.nixosModules.optionals
          self.nixosModules.basic
          self.nixosModules.includeSource
          self.nixosModules.desktop
          self.nixosModules.development

          ./system/laptop
        ];
      };

      # nix build .#nixosConfigurations.iso.config.system.build.isoImage
      iso = pkgs-stable.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          "${pkgs-stable}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ({ pkgs, ... }: {
            isoImage.forceTextMode = true;
            environment.systemPackages = [
              self.legacyPackages."${system}".auditor
            ];
            boot.supportedFilesystems = [ "bcachefs" ];
            boot.kernelPackages = lib.mkOverride 0 pkgs.linuxPackages_latest;
            boot.zfs.forceImportRoot = false; # not used here, why warning?
          })
        ];
      };

      foxtrot = let
        system = "x86_64-linux";
      in pkgs-unstable.lib.nixosSystem {
        specialArgs = commonSpecialArgs system;
        modules = [
          impermanence.nixosModules.impermanence
          self.nixosModules.${system}.onUnstablePkgs
          self.nixosModules.optionals
          self.nixosModules.basic
          self.nixosModules.includeSource

          ./system/foxtrot
        ];
      };

      bravo = let
        system = "x86_64-linux";
      in pkgs-stable.lib.nixosSystem {
        specialArgs = commonSpecialArgs system;
        modules = [
          disko.nixosModules.disko
          impermanence.nixosModules.impermanence
          self.nixosModules.${system}.onStablePkgs
          self.nixosModules.optionals
          self.nixosModules.basic

          ./system/bravo
        ];
      };

      testing = let
        system = "x86_64-linux";
      in pkgs-stable.lib.nixosSystem rec {
        specialArgs = commonSpecialArgs system;
        modules = [
          disko.nixosModules.disko
          impermanence.nixosModules.impermanence
          self.nixosModules.${system}.onStablePkgs
          self.nixosModules.optionals
          self.nixosModules.basic

          ./system/testing
        ];
      };

      charlie = let
        system = "x86_64-linux";
      in pkgs-stable.lib.nixosSystem rec {
        specialArgs = commonSpecialArgs system;
        modules = [
          disko.nixosModules.disko
          impermanence.nixosModules.impermanence
          self.nixosModules.${system}.onStablePkgs
          self.nixosModules.optionals
          self.nixosModules.basic

          ./system/charlie
        ];
      };

      hotel = let
        system = "x86_64-linux";
      in pkgs-stable.lib.nixosSystem rec {
        specialArgs = commonSpecialArgs system;
        modules = [
          disko.nixosModules.disko
          impermanence.nixosModules.impermanence
          self.nixosModules.${system}.onStablePkgs
          self.nixosModules.optionals
          self.nixosModules.basic

          ./system/hotel
        ];
      };
    };

    hydraJobs = {
      machines = lib.filterAttrs (name: _: name != "iso") (
        builtins.mapAttrs (_: node: node.config.system.build.toplevel) self.nixosConfigurations
      ) // {
        foxtrot.dom0 = self.nixosConfigurations.foxtrot.config.system.build.toplevel;
        foxtrot.domU = builtins.mapAttrs (name: value: value.definition) self.nixosConfigurations.foxtrot.config.virtualisation.xen.machines;
      };

      desktops = pkgs-stable.legacyPackages."x86_64-linux".releaseTools.aggregate { # To later allow updating only if every machine can be updated
        name = "All desktops";
        constituents = [
          "machines.DESKTOP-IJK2GUG"
          "machines.MOBILE-DCV5AQD"
        ];
      };
      # fix transient errors in hydra regarding these two IDEs
      ide-prefetch = let
        overrideMirror = drv: drv.overrideAttrs(old: {
          urls = builtins.map (oldUrl: builtins.replaceStrings ["https://download.jetbrains.com"] ["http://10.168.88.57:8000"] oldUrl) old.urls;
        });
        pkgs = pkgs-unstable.legacyPackages."x86_64-linux";
      in {
        rust-rover = overrideMirror pkgs.jetbrains.rust-rover.src;
        webstorm = overrideMirror pkgs.jetbrains.webstorm.src;
        clion = overrideMirror pkgs.jetbrains.clion.src;
      };
      stdenv."x86_64-linux" = {
        stable = pkgs-stable.legacyPackages."x86_64-linux".stdenv;
        unstable = pkgs-unstable.legacyPackages."x86_64-linux".stdenv;
      };
      packages."x86_64-linux" = {
        inherit (self.legacyPackages."x86_64-linux") dockerImages;
      };
    };
  };
}
