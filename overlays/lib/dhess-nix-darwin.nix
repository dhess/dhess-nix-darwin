self: super:

let

  localLibs = import ../../lib;

  # Provide access to the whole package, if needed.
  path = ../../.;

in
{
  lib = (super.lib or {}) // {
    dhess-nix-darwin = (super.lib.dhess-nix-darwin or {}) // {
      inherit path;

      # Access to dhess-nix-darwin's fixed nix-darwin.
      inherit (localLibs) nix-darwin;
    };
  };
}
