self: super:

let

  localLib = import ../../lib;

  # Provide access to the whole package, if needed.
  path = ../../.;

  # A list of all the nix-darwin modules exported by this package.
  modulesList = ../../modules/module-list.nix;


  # All nix-darwin modules exported by this package. To use, add this
  # expression to your configuration's list of imports.
  modules = import modulesList;


  # A convenience function for creating nix-darwin systems.
  mkSystem = configuration: import (localLib.fixedNixDarwin) {
    nixpkgs = super.lib.fetchers.fixedNixpkgs;
    system = "x86_64-darwin";
    inherit configuration;
  };

in
{
  lib = (super.lib or {}) // {
    dhess-nix-darwin = (super.lib.dhess-nix-darwin or {}) // {
      inherit path;
      inherit modules modulesList;
      inherit (localLib) sources;

      inherit mkSystem;

      # Access to dhess-nix-darwin's fixed nix-darwin.
      inherit (localLib) nix-darwin;
    };
  };
}
