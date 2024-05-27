{ config, lib, pkgs, ... }: with lib; let
  cfg = config.programs.wrappedBinaries;
  wrappedBins = pkgs.runCommand "wrapped-binaries" {
    # take precedence over non-wrapped versions
    meta.priority = -10;
  } ''
      mkdir -p $out/bin
      mkdir -p $out/share/applications
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (command: opts:
      let
        cmdline = lib.escapeShellArgs (opts.cmdline);
      in
      ''
        cat <<_EOF >$out/bin/${command}
        #!${pkgs.runtimeShell} -e
        ${lib.optionalString (opts.enableExec) "exec"} ${cmdline} "\$@"
        _EOF
        chmod 0755 $out/bin/${command}

        ${lib.optionalString (opts.desktop != null) ''
          substitute ${opts.desktop} $out/share/applications/$(basename ${opts.desktop}) \
            --replace ${opts.executable} $out/bin/${command}
        ''}
      '') cfg.binaries)}
    '';
in {
  options.programs.wrappedBinaries = {
    enable = mkEnableOption "Enable simple wrapper";

    binaries = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          cmdline = mkOption {
            type = types.listOf types.str;
            description = "List of command arguments";
            example = literalExpression ''[ "''${lib.getBin pkgs.firefox}/bin/firefox" ]'';
          };
          desktop = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = ".desktop file to modify. Only necessary if it uses the absolute path to the executable.";
            example = literalExpression ''"''${pkgs.firefox}/share/applications/firefox.desktop"'';
          };
          enableExec = mkOption {
            type = types.bool;
            default = true;
            description = "Use exec before command";
          };
        };
      });
      default = {};
      description = ''
        Wrap the binaries and place them in the global path.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ wrappedBins ];
  };
}
