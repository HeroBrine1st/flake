{
  description = "NixOS configuration";

  inputs = {
    pkgs-unstable.url = "nixpkgs/nixos-unstable";
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

  outputs = { self, pkgs-unstable, pkgs-stable, nixos-rk3588, pkgs-jetbrains-2022, home-manager, disko, impermanence, lanzaboote, fenix, pkgs-bdfr, ags, ... }: {
    packages = {
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
        bdfr = import pkgs-bdfr {
          system = "x86_64-linux";
        };
      in {
        jetbrains = jb.jetbrains;
        debounce-keyboard = pkgs.callPackage packages/debounce-keyboard {};
        organise-files = pkgs.callPackage packages/organise-files.nix {};
        tlauncher = pkgs.callPackage packages/tlauncher {};
        fenix = rust.fenix;
        bdfr = bdfr.callPackage packages/bdfr {};
        topbar = import packages/topbar { inherit pkgs ags; };
      };
      "aarch64-linux" = let
        bdfr = import pkgs-bdfr {
          system = "aarch64-linux";
        };
      in {
        bdfr = bdfr.callPackage packages/bdfr {};
      };
    };
    nixosConfigurations = {
      opi5 = let
        # using the same nixpkgs as nixos-rk3588 to utilize the cross-compilation cache.
        inherit (nixos-rk3588.inputs) nixpkgs;
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
          ./modules/nebula
          ./modules/python.nix

          ./common/cli
          ./common/scrutiny-collector.nix

          ./system/opi5/configuration.nix
          ./system/opi5/hardware-configuration.nix
          ./system/opi5/impermanence.nix
          ./system/opi5/btrbk.nix
        ];
      };
      DESKTOP-IJK2GUG = pkgs-unstable.lib.nixosSystem {
        specialArgs = {
          custom-pkgs = self.packages."x86_64-linux";
        };
        modules = [
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          ./modules/wrappers.nix
          ./modules/syncthing.nix
          ./modules/nebula
          ./modules/unfree.nix
          ./modules/python.nix

          ./common/cli
          ./common/scrutiny-collector.nix

          ./common/desktop

          ./common/development

          ./system/pc/configuration.nix

          ./system/pc/syncthing.nix
          ./system/pc/users.nix
          ./system/pc/hardware-configuration.nix
          ./system/pc/hardware-dconf.nix
          ./system/pc/impermanence.nix
          ./system/pc/hardware-mitigations.nix
        ];
      };
      MOBILE-DCV5AQD = pkgs-unstable.lib.nixosSystem {
        specialArgs = {
          custom-pkgs = self.packages."x86_64-linux";
        };
        modules = [
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          lanzaboote.nixosModules.lanzaboote
          ./modules/wrappers.nix
          ./modules/syncthing.nix
          ./modules/nebula
          ./modules/unfree.nix
          ./modules/python.nix

          ./common/cli
          ./common/scrutiny-collector.nix

          ./common/desktop
          ./common/desktop/hyprland

          ./common/development

          ./system/laptop/configuration.nix

          ./system/laptop/hardware-configuration.nix
          ./system/laptop/hardware-dconf.nix
          ./system/laptop/impermanence.nix
          ./system/laptop/syncthing.nix

          ./system/laptop/lanzaboote.nix
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
        specialArgs = {
          custom-pkgs = self.packages."x86_64-linux";
          unstable-pkgs = {
            open-webui = pkgs-unstable.legacyPackages."x86_64-linux".open-webui;
            ollama = pkgs-unstable.legacyPackages."x86_64-linux".ollama;
          };
        };
        modules = [
          impermanence.nixosModules.impermanence
          ./modules/python.nix
          ./common/cli
          ./system/foxtrot
        ];
      };

      bravo = pkgs-stable.lib.nixosSystem {
        specialArgs = {
          custom-pkgs = self.packages."x86_64-linux";
        };
        modules = [
          disko.nixosModules.disko
          impermanence.nixosModules.impermanence
          ./modules/python.nix
          ./common/cli
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
