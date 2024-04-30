{ config, pkgs, lib, ... }: {
  nixpkgs.overlays = [
    (final: prev: {
      bash-completion = prev.bash-completion.overrideAttrs (oldAttrs: {
        version = "2.11";
      });
    })
  ];
}