{ config, lib, pkgs, ... }:

let

  cfg = config.dhess-nix-darwin.remote-build-host;
  enabled = cfg.enable;

  authorizedKeys =
  let
    userEnvironment = lib.concatStringsSep " " [
      "NIX_REMOTE=daemon"
      "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
  in
  map
    (keyLiteral:
      "command=\"${userEnvironment} ${config.nix.package}/bin/nix-store --serve --write\" ${keyLiteral}")
    (map builtins.readFile cfg.user.sshPublicKeyFiles);

in
{
  options.dhess-nix-darwin.remote-build-host = {
    enable = lib.mkEnableOption ''
      remote build support on this host; i.e., configure the machine
      so that it can perform Nix builds for other hosts.
      
      Enabling this option will create a user account that is
      dedicated to remote builds. This user will be added to
      <literal>nix.trustedUsers</literal>.

      The remote build user's SSH environment will be configured so
      that it can only run the Nix commands needed to host remote Nix
      builds. The remote build user will be added to
      <option>nix.trustedUsers</option>, as required for it to host
      remote Nix builds, but is otherwise non-privileged.
    '';

    user = {
      name = lib.mkOption {
        type = pkgs.lib.types.nonEmptyStr;
        default = "remote-builder";
        readOnly = true;
        description = ''
          The name of the user that's created by this module to run
          remote builds.

          This is a read-only attribute and is provided so that other
          modules can refer to it.
        '';
      };

      uid = lib.mkOption {
        type = lib.types.ints.positive;
        default = 5001;
        example = 502;
        description = ''
          The uid of the user that's created by this module to run
          remote builds.
        '';
      };

      gid = lib.mkOption {
        type = lib.types.ints.positive;
        default = cfg.user.uid;
        example = 502;
        description = ''
          The gid of the user that's created by this module to run
          remote builds.

          By default, this value is the same as the user ID set in the
          <option>uid</option>.
        '';
      };

      sshPublicKeyFiles = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        example = lib.literalExample [ ./remote-builder.pub ];
        description = ''
          The public SSH key files used to identify the remote builder
          user. The corresponding private keys should be installed on
          the build host that is using this remote build host.
        '';
      };
    };
  };

  config = lib.mkIf enabled {
    nix.trustedUsers = [ cfg.user.name ];

    users.knownGroups = lib.singleton cfg.user.name;
    users.knownUsers = lib.singleton cfg.user.name;
    users.groups."${cfg.user.name}" = {
      gid = cfg.user.gid;
      description = "Nix remote builder group";
      members = lib.singleton cfg.user.name;
    };
    users.users."${cfg.user.name}" = {
      uid = cfg.user.uid;
      gid = cfg.user.gid;
      description = "Nix remote builder";
      home = "/Users/${cfg.user.name}";
      shell = "/bin/zsh";
      isHidden = true;
    };

    environment.etc."per-user/${cfg.user.name}/ssh/authorized_keys".text =
      lib.concatStringsSep "\n" authorizedKeys;

    system.activationScripts.postActivation.text = ''
      printf "configuring ssh keys for ${cfg.user.name}... "
      mkdir -p ~${cfg.user.name}/.ssh
      chmod 0700 ~${cfg.user.name}/.ssh
      cp -f /etc/per-user/${cfg.user.name}/ssh/authorized_keys ~${cfg.user.name}/.ssh/authorized_keys
      chown -R ${cfg.user.name}:${cfg.user.name} ~${cfg.user.name}
      echo "ok"
    '';
  };
}
