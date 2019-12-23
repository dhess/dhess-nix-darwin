# Based on
# https://github.com/input-output-hk/iohk-ops/blob/df01a228e559e9a504e2d8c0d18766794d34edea/jobsets/default.nix

{ nixpkgs ? <nixpkgs>
, declInput ? {}
}:

let

  dhessNixDarwinUri = "git@github.com:dhess/dhess-nix-darwin.git";

  mkFetchGithub = value: {
    inherit value;
    type = "git";
    emailresponsible = false;
  };

  pkgs = import nixpkgs {};

  defaultSettings = {
    enabled = 1;
    hidden = false;
    keepnr = 5;
    schedulingshares = 400;
    checkinterval = 60;
    enableemail = false;
    emailoverride = "";
    nixexprpath = "jobsets/release.nix";
    nixexprinput = "dhessNixDarwin";
    description = "My nix-darwin modules";
    inputs = {
      dhessNixDarwin = mkFetchGithub "${dhessNixDarwinUri} master";
    };
  };

  # These run less frequently, so that they don't interfere with
  # checkins on the master branch.
  mkAlternate = dhessNixDarwinBranch: dhessNixRev: nixDarwinRev: {
    checkinterval = 60 * 60 * 3;
    inputs = {
      dhessNixDarwin = mkFetchGithub "${dhessNixDarwinUri} ${dhessNixDarwinBranch}";
      dhess_nix = mkFetchGithub "https://github.com/dhess/dhess-nix.git ${dhessNixRev}";
      nix_darwin = mkFetchGithub "https://github.com/LnL7/nix-darwin.git ${nixDarwinRev}";
    };
  };

  mainJobsets = with pkgs.lib; mapAttrs (name: settings: defaultSettings // settings) (rec {
    master = {};
    next = mkAlternate "master" "master" "master";
  });

  jobsetsAttrs = mainJobsets;

  jobsetJson = pkgs.writeText "spec.json" (builtins.toJSON jobsetsAttrs);

in {
  jobsets = with pkgs.lib; pkgs.runCommand "spec.json" {} ''
    cat <<EOF
    ${builtins.toJSON declInput}
    EOF
    cp ${jobsetJson} $out
  '';
}
