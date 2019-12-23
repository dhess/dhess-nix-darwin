self: super:

let

  localLib = import ../lib;

  build-host = super.lib.dhess-nix-darwin.mkSystem ../examples/build-host.nix;
  remote-builder = super.lib.dhess-nix-darwin.mkSystem ../examples/remote-builder.nix;

in
{
  inherit build-host;
  inherit remote-builder;
}
