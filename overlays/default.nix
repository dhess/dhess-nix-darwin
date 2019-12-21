# Local overlays.

self: super:

let

  localLib = import ../lib;

  macnix-rebuild = super.callPackage ../pkgs/macnix-rebuild {};

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
  inherit macnix-rebuild;
  inherit build-host;
  inherit remote-builder;
}
