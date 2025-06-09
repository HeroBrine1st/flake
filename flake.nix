{
  description = "NixOS configuration";

  inputs = {
    pkgs-unstable.url = "nixpkgs/nixos-unstable-small";
    pkgs-stable.url = "nixpkgs/nixos-25.05";
    pkgs-jetbrains-2022.url = "github:NixOS/nixpkgs?rev=e1fa54a56982c5874f6941703c8b760541e40db1";
    pkgs-bdfr.url = "github:NixOS/nixpkgs?rev=59b1aef59071cae6e87859dc65de973d2cc595c0"; # pinned
    nixos-rk3588.url = "github:HeroBrine1st/nixos-rk3588?rev=74fa6122e8248fa9af0a7fa6a6e5f949b73be963"; # pinned
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
    lib = pkgs-unstable.lib;
    forAllSystems = f: lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: f system);
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
    # I'm sick of "flake attribute '...' is not a derivation"
    legacyPackages."x86_64-linux" = let
      pkgs = pkgs-unstable.legacyPackages."x86_64-linux";
    in {
      jetbrains = (import pkgs-jetbrains-2022 {
        system = "x86_64-linux";
        config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [ "idea-ultimate" "pycharm-professional" "clion" ];
      }).jetbrains;
      fenix = (import pkgs-unstable {
        system = "x86_64-linux";
        overlays = [ fenix.overlays.default ];
      }).fenix;
      topbar = import packages/topbar { inherit pkgs ags; };
    };
    packages = lib.recursiveUpdate
      (forAllSystems (system: let bdfr = pkgs-bdfr.legacyPackages."${system}"; in {
          bdfr = bdfr.callPackage packages/bdfr {};
      }))
      {
        "x86_64-linux" = let
          pkgs = pkgs-unstable.legacyPackages."x86_64-linux";
        in {
          debounce-keyboard = pkgs.callPackage packages/debounce-keyboard {};
          organise-files = pkgs.callPackage packages/organise-files.nix {};
          tlauncher = pkgs.callPackage packages/tlauncher {};
          arc-x-icon-theme = pkgs.callPackage packages/arc-x-icons.nix {};
        };
      };
    nixosConfigurations = let
      commonSpecialArgs = system: {
        custom-pkgs = self.packages."${system}" // (if system == "x86_64-linux" then self.legacyPackages."${system}" else {});
        assets = ./assets;
        systems = import ./systems.nix;
      };
    in {
      alfa = let
        inherit (nixos-rk3588.inputs) nixpkgs; # pinning nixpkgs so that kernel is not rebuilt due to system update
        system = "aarch64-linux";
      in pkgs-stable.lib.nixosSystem {
        inherit system;
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
          self.nixosModules.optionals
          self.nixosModules.basic
          self.nixosModules.scrutiny-collector

          ./system/alfa
        ];
      };
      DESKTOP-IJK2GUG = pkgs-unstable.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = commonSpecialArgs system;
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
      MOBILE-DCV5AQD = pkgs-unstable.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = commonSpecialArgs system;
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

      foxtrot = pkgs-stable.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          unstable-pkgs = let pkgs = import pkgs-unstable {
            system = "x86_64-linux";
            config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [ "open-webui" ];
          }; in {
            open-webui = pkgs.open-webui;
            ollama = pkgs.ollama;
          };
        } // commonSpecialArgs system;
        modules = [
          impermanence.nixosModules.impermanence
          self.nixosModules.optionals
          self.nixosModules.basic
          self.nixosModules.scrutiny-collector

          ./system/foxtrot
        ];
      };

      bravo = pkgs-stable.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = commonSpecialArgs system;
        modules = [
          disko.nixosModules.disko
          impermanence.nixosModules.impermanence
          self.nixosModules.optionals
          self.nixosModules.basic

          ./system/bravo
        ];
      };
    };

    hydraJobs = {
      machines = pkgs-stable.lib.filterAttrs (name: _: name != "iso") (
        builtins.mapAttrs (_: node: node.config.system.build.toplevel) self.nixosConfigurations
      );
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
      };
    };
  };
}
