{
  description = "NixOS configuration";

  inputs = {
    pkgs-unstable.url = "nixpkgs/nixos-unstable";
    pkgs-stable.url = "nixpkgs/nixos-23.11";
    nixos-rk3588.url = "github:ryan4yin/nixos-rk3588?rev=349f39dcaafeb41250544bcc066db8668a7762ce";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { pkgs-unstable, nixos-rk3588, home-manager, ... }: {
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
#          nixos-rk3588.nixosModules.orangepi5.sd-image
          ./system/opi5/configuration.nix
          ./system/opi5/hardware-configuration.nix
        ];
      };
      DESKTOP-IJK2GUG = pkgs-unstable.lib.nixosSystem {
        modules = [
          home-manager.nixosModules.home-manager
          ./system/pc/configuration.nix
          ./system/pc/hardware-configuration.nix
          ./system/pc/home.nix
        ];
      };
    };
  };
}
