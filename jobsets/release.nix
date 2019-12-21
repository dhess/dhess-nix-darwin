## This builds all dhess-nix-darwin pacakges. It's indended for
## Hydra/full package builds.

let

  lib = import ../lib;
  fixedNixpkgs = lib.fixedNixpkgs;
  localPkgs = (import ../.) {};

in

{ supportedSystems ? [ "x86_64-darwin" "x86_64-linux" ]
, scrubJobs ? true
, nixpkgsArgs ? {
    config = { allowUnfree = true; allowBroken = true; inHydra = true; };
    overlays = [ localPkgs.overlays.dhess-nix-darwin ];
  }
}:

with import (fixedNixpkgs + "/pkgs/top-level/release-lib.nix") {
  inherit supportedSystems scrubJobs nixpkgsArgs;
};

let

  darwin = [ "x86_64-darwin" ];
  x86_64 = [ "x86_64-linux" "x86_64-darwin" ];
  x86_64_linux = [ "x86_64-linux" ];
  linux = [ "x86_64-linux" ];

  jobs = (mapTestOn {
    macnix-rebuild = darwin;
    build-host.system = darwin;
    remote-builder.system = darwin;
  })
  //
  {
    nix-darwin-configs = pkgs.releaseTools.aggregate {
      name = "nix-darwin-configs";
      meta.description = "Example nix-darwin configurations";
      meta.maintainer = lib.maintainers.dhess-pers;
      constituents = with jobs; [
        build-host.system.x86_64-darwin
        remote-builder.system.x86_64-darwin
      ];
    };

    x86_64-darwin = pkgs.releaseTools.aggregate {
      name = "dhess-nix-darwin-x86_64-darwin";
      meta.description = "dhess-nix-darwin packages (x86_64-darwin)";
      meta.maintainer = lib.maintainers.dhess-pers;
      constituents = with jobs; [
        macnix-rebuild.x86_64-darwin
      ];
    };
  };

in
jobs
