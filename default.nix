let

  lib = (import ./lib);
  defaultPkgs = lib.nixpkgs { config = { allowBroken = true; allowUnfree = true; }; };

in

{ pkgs ? defaultPkgs }:

let

  dhessNixDarwinOverlays = self: super:
    lib.customisation.composeOverlays lib.overlays super;
  dhessNixDarwinPkgs = lib.customisation.composeOverlays (lib.singleton dhessNixDarwinOverlays) pkgs;

in
{
  # Example nix-darwin configs.
  inherit (dhessNixDarwinPkgs) build-host remote-builder;

  # nix-drawin helper script.
  inherit (dhessNixDarwinPkgs) macnix-rebuild;

  # Overlays for the dhess-nix-darwin package.
  overlays.dhess-nix-darwin = dhessNixDarwinOverlays;
}
