self: super:

let

  localLib = import ../lib;

  build-host = import (localLib.fixedNixDarwin) {
    nixpkgs = super.lib.fetchers.fixedNixpkgs;
    configuration = ../examples/build-host.nix;
  };

  remote-builder = import (localLib.fixedNixDarwin) {
    nixpkgs = super.lib.fetchers.fixedNixpkgs;
    configuration = ../examples/remote-builder.nix;
  };

in
{
  inherit build-host;
  inherit remote-builder;
}
