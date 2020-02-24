{ config
, pkgs
, lib
, ...
}:

let

  cfg = config.dhess-nix-darwin.build-host;

  sshKeyName = host: user: "${user}_at_${host}";

  mkBuildMachines = remoteBuildHosts: lib.mapAttrsToList (host: descriptor: with descriptor;
    {
      inherit hostName systems maxJobs speedFactor mandatoryFeatures supportedFeatures;
      sshUser = "ssh://${sshUserName}";
      sshKey =
      let
        keyname = sshKeyName host sshUserName;
      in
        "${cfg.sshKeyDir}/${keyname}";
    }
  ) remoteBuildHosts;

  knownHosts = remoteBuildHosts: lib.mapAttrsToList (host: descriptor:
    {
      hostNames = lib.singleton descriptor.hostName ++ descriptor.alternateHostNames;
      publicKey = descriptor.hostPublicKeyLiteral;
    }
  ) remoteBuildHosts;

  mkHostPortPairs = remoteBuildHosts: lib.mapAttrsToList (_: descriptor: with descriptor;
    { inherit hostName port; }
  ) remoteBuildHosts;

  sshExtraConfig = remoteBuildHosts: lib.concatMapStrings (pair:
    lib.optionalString (pair.port != null) ''

      Host ${pair.hostName}
      Port ${toString pair.port}
    ''
  ) (mkHostPortPairs remoteBuildHosts);

  sshConfig = pkgs.writeText "ssh_config" (sshExtraConfig cfg.buildMachines);

in
{
  options.dhess-nix-darwin.build-host = {
    enable = lib.mkEnableOption ''
      build-host support, i.e., a machine from which nixpkgs builds
      can be performed using remote builders.

      This module will configure this host to use the given remote
      build hosts as remote builders. This includes setting the
      <option>nix.buildMachines</option>, as well as all of the user
      and host keys needed by SSH to log into those remote builders
      without needing any manual set-up. (For example, most Nix guides
      to remote builds tell you to manually SSH to the remote build
      host once before enabling remote builds, in order to get SSH to
      accept the remote build host's host key; but if you configure
      this module properly, that will not be necessary.)
    '';

    sshKeyDir = lib.mkOption {
      type = pkgs.lib.types.nonEmptyStr;
      default = "/var/lib/remote-build-keys";
      example = "/etc/nix";
      description = ''
        A directory where the files containing the SSH private keys
        for the remote build host users are stored.

        These key files must be deployed via another method. This
        module only configures the target host's nix-daemon to look in
        this location for the key files.
      '';
    };

    buildMachines = lib.mkOption {
      default = {};
      description = ''
        An attrset containing remote build host descriptors.

        The machines in this attrset will be added to
        <literal>/etc/nix/machines</literal>, so that they're used by
        <literal>nix-daemon</literal> for remote builds that are
        initiated from this host.
      '';
      type = lib.types.attrsOf pkgs.lib.types.remoteBuildHost;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {  assertion = cfg.buildMachines != {};
         message = "`dhess-nix-darwin.build-host` is enabled, but `dhess-nix-darwin.build-host.buildMachines` is empty";
      }
    ];

    nix.extraOptions = ''
      keep-derivations = true
      keep-outputs = true
    '';

    nix.distributedBuilds = true;
    nix.buildMachines = mkBuildMachines cfg.buildMachines;
    programs.ssh.knownHosts = knownHosts cfg.buildMachines;

    system.activationScripts.postActivation.text = ''
      mkdir -p ~root/.ssh
      chmod 0700 ~root/.ssh
      cp -f ${sshConfig} ~root/.ssh/config
      chown -R root:root ~root/.ssh/config
      chmod 0400 ~root/.ssh/config
    '';
  };
}
