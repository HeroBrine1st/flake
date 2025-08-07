# This module removes last impurity in NixOS: the uid-map and gid-map, instead requiring those maps to be in-tree.
# See https://github.com/NixOS/nixpkgs/blob/5b09dc45f24cf32316283e62aec81ffee3c3e376/nixos/modules/config/update-users-groups.pl#L10
# to confirm uid-map and gid-map are used even with mutableUsers=false
# Despite [here](https://github.com/NixOS/nixpkgs/issues/2821) being said otherwise

{ lib, config, ... }: {
  options = {
    users = {
      uidMapFile = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.path;
        description = "A mapping between user name and UID, the same as /var/lib/nixos/uid-map";
      };
      gidMapFile = lib.mkOption {
        default = null;
        type = lib.types.nullOr lib.types.path;
        description = "A mapping between group name and GID, the same as /var/lib/nixos/gid-map";
      };
    };
  };

  config = lib.mkIf (config.users.uidMapFile != null || config.users.gidMapFile != null) {
    # TODO /etc/subuid and /etc/subgid (strictly avoid auto-subuid-map file)
    assertions = let
      uidMap = builtins.fromJSON (builtins.readFile config.users.uidMapFile);
      gidMap = builtins.fromJSON (builtins.readFile config.users.gidMapFile);
      dynamicUserNames = builtins.attrNames (lib.filterAttrs (name: value: value.uid == null && !(uidMap ? name)) config.users.users);
      dynamicGroupNames = builtins.attrNames (lib.filterAttrs (name: value: value.gid == null && !(gidMap ? name)) config.users.groups);
    in lib.optionals (config.users.uidMapFile != null) [{
      assertion = builtins.length dynamicUserNames == 0;
      message = "Users ${lib.strings.concatStringsSep ", " dynamicUserNames} have no uid available and static uids are requested";
    }] ++ lib.optionals (config.users.gidMapFile != null) [{
      assertion = builtins.length dynamicGroupNames == 0;
      message = "Groups ${lib.strings.concatStringsSep ", " dynamicGroupNames} have no gid available and static gids are requested";
    }] ++ [{
      assertion = !config.users.mutableUsers;
      message = "statis-ids module requires immutable users";
    }];

    # declarative-users is used for adding non-declarative users to changed groups and to show log line if user is removed declaratively.
    # Both cases are only applicable if mutableUsers is true.
    # declarative-groups i
    system.activationScripts = {
      "uid-map" = lib.optionalString (config.users.uidMapFile != null) "ln -s ${config.users.uidMapFile} /var/lib/nixos/uid-map";
      "gid-map" = lib.optionalString (config.users.gidMapFile != null) "ln -s ${config.users.gidMapFile} /var/lib/nixos/gid-map";
      "users".deps = [ "uid-map" "gid-map" ];
    };
  };
}
