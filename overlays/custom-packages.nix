self: super:

let

  macnix-rebuild = super.callPackage ../pkgs/macnix-rebuild {};

in
{
  inherit macnix-rebuild;
}
