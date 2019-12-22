self: super:

let

  localLibs = import ../../lib;

  # Provide access to the whole package, if needed.
  path = ../../.;

  # A list of all the nix-darwin modules exported by this package.
  modulesList = ../../modules/module-list.nix;


  # All nix-darwin modules exported by this package. To use, add this
  # expression to your configuration's list of imports.
  modules = import modulesList;

in
{
  lib = (super.lib or {}) // {
    dhess-nix-darwin = (super.lib.dhess-nix-darwin or {}) // {
      inherit path;
      inherit modules modulesList;
      inherit (localLibs) sources;

      # Access to dhess-nix-darwin's fixed nix-darwin.
      inherit (localLibs) nix-darwin;
    };
  };
}
