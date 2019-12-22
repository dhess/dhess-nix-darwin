let

  lib = (import ./lib);
  defaultPkgs = lib.nixpkgs { config = { allowBroken = true; allowUnfree = true; }; };

in

{ pkgs ? defaultPkgs }:

let

  overlays = self: super:
    lib.customisation.composeOverlays lib.overlays super;
  self = lib.customisation.composeOverlays (lib.singleton overlays) pkgs;

in
{
  # Example nix-darwin configs.
  inherit (self) build-host remote-builder;

  # nix-drawin helper script.
  inherit (self) macnix-rebuild;

  # Library functions.
  inherit (self) lib;

  # Overlays for the dhess-nix-darwin package.
  overlays.dhess-nix-darwin = overlays;
}
