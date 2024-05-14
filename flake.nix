{
  description = "NixOS configuration";

  inputs = {
    pkgs-unstable.url = "nixpkgs/nixos-unstable";
    pkgs-stable.url = "nixpkgs/nixos-23.11";
    pkgs-jetbrains-2022-3-3.url = "github:NixOS/nixpkgs?rev=f6aa4144d0c38231d8c383facf40f63b13759bb5";
    #nixos-rk3588.url = "github:ryan4yin/nixos-rk3588?rev=349f39dcaafeb41250544bcc066db8668a7762ce";
    nixos-rk3588.url = "github:HeroBrine1st/nixos-rk3588?rev=7f20d6763f6e8a19b0ce361efce5c0bab776001d";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs.follows = "pkgs-unstable";
      };
    };
  };

  outputs = { self, pkgs-unstable, nixos-rk3588, pkgs-jetbrains-2022-3-3, home-manager, ... }: {
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
      in nixpkgs.lib.nixosSystem {
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
        };
        modules = [
          home-manager.nixosModules.home-manager
          ./system/pc/configuration.nix
          ./system/pc/hardware-configuration.nix
          ./system/pc/home.nix
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
