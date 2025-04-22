{
  description = "NixOS configuration";

  inputs = {
    pkgs-unstable.url = "nixpkgs/nixos-unstable-small";
    pkgs-stable.url = "nixpkgs/nixos-24.11";
    pkgs-jetbrains-2022.url = "github:NixOS/nixpkgs?rev=e1fa54a56982c5874f6941703c8b760541e40db1";
    pkgs-bdfr.url = "github:NixOS/nixpkgs?rev=59b1aef59071cae6e87859dc65de973d2cc595c0"; # pinned
    nixos-rk3588.url = "github:ryan4yin/nixos-rk3588?rev=c4fef04d8c124146e6e99138283e0c57b2ad8e29"; # pinned
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "pkgs-unstable";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "pkgs-unstable";
    };
    impermanence.url = "github:nix-community/impermanence";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "pkgs-unstable";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "pkgs-unstable";
    };
    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "pkgs-unstable";
    };
  };

  outputs = { self, pkgs-unstable, pkgs-stable, nixos-rk3588, pkgs-jetbrains-2022, home-manager, disko, impermanence, lanzaboote, fenix, pkgs-bdfr, ags, ... }: let
    forAllSystems = f: pkgs-stable.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: f system);
  in {
    nixosModules = {
      optionals = ./modules/optionals; # "optionals" means that they require an option to be enabled
      basic = ./modules/common;
      scrutiny-collector = ./modules/common/scrutiny-collector.nix;
      syncthing = ./modules/common/syncthing.nix;
      desktop = ./modules/common/desktop;
      development = ./modules/common/development;
      hyprland = ./modules/common/desktop/hyprland;
    };
    packages = pkgs-stable.lib.recursiveUpdate
      (forAllSystems (system: let bdfr = import pkgs-bdfr { system = system; }; in {
          bdfr = bdfr.callPackage packages/bdfr {};
      }))
      {
        "x86_64-linux" = let
          pkgs = import pkgs-unstable {
            system = "x86_64-linux";
          };
          jb = import pkgs-jetbrains-2022 {
            system = "x86_64-linux";
            config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [ "idea-ultimate" "pycharm-professional" "clion" ];
          };
          rust = import pkgs-unstable {
            system = "x86_64-linux";
            overlays = [ fenix.overlays.default ];
          };
        in {
          jetbrains = jb.jetbrains;
          debounce-keyboard = pkgs.callPackage packages/debounce-keyboard {};
          organise-files = pkgs.callPackage packages/organise-files.nix {};
          tlauncher = pkgs.callPackage packages/tlauncher {};
          fenix = rust.fenix;
          topbar = import packages/topbar { inherit pkgs ags; };
          arc-x-icon-theme = pkgs.callPackage packages/arc-x-icons.nix {};
        };
      };
    nixosConfigurations = {
      alfa = let
        inherit (nixos-rk3588.inputs) nixpkgs; # pinning nixpkgs so that kernel is not rebuilt due to system update
        system = "aarch64-linux";
      in pkgs-stable.lib.nixosSystem {
        inherit system;
        specialArgs = {
          rk3588 = {
            inherit nixpkgs;
            pkgsKernel = import nixpkgs {
              inherit system;
            };
          };
          custom-pkgs = self.packages."aarch64-linux";
        };

        modules = [
          nixos-rk3588.nixosModules.orangepi5.core
          impermanence.nixosModules.impermanence
          self.nixosModules.optionals
          self.nixosModules.basic
          self.nixosModules.scrutiny-collector

          ./system/opi5
        ];
      };
      DESKTOP-IJK2GUG = pkgs-unstable.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          custom-pkgs = self.packages."x86_64-linux";
          assets = ./assets;
        };
        modules = [
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          self.nixosModules.optionals
          self.nixosModules.basic
          self.nixosModules.scrutiny-collector
          self.nixosModules.syncthing
          self.nixosModules.desktop
          self.nixosModules.development

          ./system/pc
        ];
      };
      MOBILE-DCV5AQD = pkgs-unstable.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          custom-pkgs = self.packages."x86_64-linux";
          assets = ./assets;
        };
        modules = [
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
          self.nixosModules.optionals
          self.nixosModules.basic
          self.nixosModules.scrutiny-collector
          self.nixosModules.syncthing
          self.nixosModules.desktop
          self.nixosModules.hyprland
          self.nixosModules.development

          ./system/laptop
        ];
      };

      unite-shell-debug-vm = pkgs-unstable.lib.nixosSystem {
        specialArgs = {
          custom-pkgs = self.packages."x86_64-linux";
        };
        modules = [
          home-manager.nixosModules.home-manager
          ./system/unite-shell-debug-vm/configuration.nix
        ];
      };

      # nix build .#nixosConfigurations.iso.config.system.build.isoImage
      iso = pkgs-stable.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${pkgs-stable}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ({ pkgs, ... }: {
            isoImage.forceTextMode = true;
          })
        ];
      };

      foxtrot = pkgs-stable.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          custom-pkgs = self.packages."x86_64-linux";
          unstable-pkgs = {
            open-webui = pkgs-unstable.legacyPackages."x86_64-linux".open-webui;
            ollama = pkgs-unstable.legacyPackages."x86_64-linux".ollama;
          };
        };
        modules = [
          impermanence.nixosModules.impermanence
          self.nixosModules.optionals
          self.nixosModules.basic
          self.nixosModules.scrutiny-collector

          ./system/foxtrot
        ];
      };

      bravo = pkgs-stable.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          custom-pkgs = self.packages."x86_64-linux";
        };
        modules = [
          disko.nixosModules.disko
          impermanence.nixosModules.impermanence
          self.nixosModules.optionals
          self.nixosModules.basic

          ./system/bravo
        ];
      };
    };
    devShells."x86_64-linux" = let
      pkgs = import pkgs-unstable { system = "x86_64-linux"; };
    in {
      opengl = pkgs.callPackage shells/opengl {};
    };
  };
}
