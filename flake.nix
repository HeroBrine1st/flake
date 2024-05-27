{
  description = "NixOS configuration";

  inputs = {
    pkgs-unstable.url = "nixpkgs/nixos-unstable";
    pkgs-stable.url = "nixpkgs/nixos-23.11";
    pkgs-jetbrains-2022-3-3.url = "github:NixOS/nixpkgs?rev=f6aa4144d0c38231d8c383facf40f63b13759bb5";
    nixos-rk3588 = {
      url = "github:ryan4yin/nixos-rk3588?rev=c4fef04d8c124146e6e99138283e0c57b2ad8e29";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs.follows = "pkgs-unstable";
      };
    };
    disko = {
      url = "github:nix-community/disko";
      inputs = {
        nixpkgs.follows = "pkgs-unstable";
      };
    };
  };

  outputs = { self, pkgs-unstable, pkgs-stable, nixos-rk3588, pkgs-jetbrains-2022-3-3, home-manager, disko, ... }: {
    packages."x86_64-linux" = let
      pkgs = import pkgs-unstable {
        system = "x86_64-linux";
        config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [ "spotify" ];
      };
      jb = import pkgs-jetbrains-2022-3-3 {
        system = "x86_64-linux";
        config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [ "pycharm-professional" ];
      };
    in {
      spotify = pkgs.callPackage packages/spotify.nix {};
      pycharm-professional = jb.jetbrains.pycharm-professional;
      debounce-keyboard = pkgs.callPackage packages/debounce-keyboard {};
      # https://github.com/scop/bash-completion/issues/1157
      bash-completion = pkgs.callPackage packages/bash-completion.nix {};
      vesktop = pkgs.callPackage packages/vesktop {};
      organise-files = pkgs.callPackage packages/organise-files.nix {};
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
        };

        modules = [
          nixos-rk3588.nixosModules.orangepi5.core
          ./system/opi5/configuration.nix
          ./system/opi5/hardware-configuration.nix
        ];
      };
      DESKTOP-IJK2GUG = pkgs-unstable.lib.nixosSystem {
        specialArgs = {
          custom-pkgs = self.packages."x86_64-linux";
          syncthing-devices = import ./const/syncthing-devices.nix;
        };
        modules = [
          home-manager.nixosModules.home-manager
          ./modules/wrappers.nix

          ./common/unfree.nix
          ./common/cli-packages.nix

          ./common/desktop/configuration.nix
          ./common/desktop/firejail.nix

          ./common/desktop/home.nix
          ./common/desktop/dconf.nix

          ./system/pc/syncthing.nix
          ./system/pc/users.nix
          ./system/pc/hardware-configuration.nix
          ./system/pc/hardware-dconf.nix
          ./system/pc/hardware-home.nix
          ./system/pc/hardware-mitigations.nix
        ];
      };
      MOBILE-DCV5AQD = pkgs-unstable.lib.nixosSystem {
        specialArgs = {
          custom-pkgs = self.packages."x86_64-linux";
          syncthing-devices = import ./const/syncthing-devices.nix;
        };
        modules = [
          home-manager.nixosModules.home-manager
          disko.nixosModules.disko
          ./modules/wrappers.nix

          ./common/unfree.nix
          ./common/cli-packages.nix

          ./common/desktop/configuration.nix
          ./common/desktop/firejail.nix

          ./common/desktop/home.nix
          ./common/desktop/dconf.nix

          ./system/laptop/syncthing.nix
          ./system/laptop/users.nix
          ./system/laptop/hardware-configuration.nix
          ./system/laptop/hardware-dconf.nix
          ./system/laptop/hardware-home.nix
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
