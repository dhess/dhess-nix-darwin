let

  sources = import ../nix/sources.nix;

  fixedDhessNix =
  let
    try = builtins.tryEval <dhess_nix>;
  in
    if try.success
      then builtins.trace "Using <dhess_nix>" try.value
    else sources.dhess-nix;

  dhess-nix = (import fixedDhessNix) {};
  inherit (dhess-nix) lib;
  inherit (lib.fetchers) fixedNixpkgs;
  inherit (lib.dhess-lib-nix) nixpkgs;

  fixedNixDarwin = lib.fetchers.fixedNixSrc "nix_darwin" sources.nix-darwin;
  nix-darwin = (import fixedNixDarwin) {};

  modulesList = ../modules/module-list.nix;
  modules = import modulesList;

  path = ./..;

  overlays = (lib.singleton dhess-nix.overlays.all)
  ++ (map import [
    ../overlays
  ]);

in lib //
{
  inherit fixedNixpkgs;
  inherit nixpkgs;
  inherit fixedNixDarwin;
  inherit nix-darwin;

  inherit path;

  inherit modules modulesList;
  inherit overlays;
}
