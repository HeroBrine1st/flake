{
  nixpkgs,
  pulls,
  refs,
  ...
}@inputs: let
  pkgs = import inputs.nixpkgs {};
  repo = "HeroBrine1st/flake";

  prs = builtins.fromJSON (builtins.readFile inputs.pulls);
  refs = builtins.fromJSON (builtins.readFile inputs.refs);
  prJobsets =
    pkgs.lib.mapAttrs (
      num: info: {
        enabled = 1;
        hidden = false;
        description = "PR ${num}: ${info.title}";
        checkinterval = 60;
        schedulingshares = 20;
        enableemail = false;
        emailoverride = "";
        keepnr = 1;
        type = 1;
        flake = "github:${repo}/pull/${num}/head";
      }
    )
    prs;
  mkFlakeJobset = branch: {
    description = "Build ${branch} (fixed revision)";
    checkinterval = 3600;
    enabled = "1";
    schedulingshares = 100;
    enableemail = false;
    emailoverride = "";
    keepnr = 1;
    hidden = false;
    type = 1;
#    flake = "github:${repo}?rev=${refs."${branch}".object.sha}";
    flake = "github:${repo}/${branch}";
  };

  # desc = prJobsets // {
  desc = {
    "master" = mkFlakeJobset "master";
  };
in {
  jobsets = pkgs.runCommand "spec-jobsets.json" {} ''
    cat > $out <<EOF
      ${builtins.toJSON desc}
    EOF
    ${pkgs.jq}/bin/jq . $out
  '';
}