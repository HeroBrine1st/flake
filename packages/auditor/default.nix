{ writeShellApplication, nix, ... }: writeShellApplication {
  name = "auditor";
  runtimeInputs = [ nix ];
  text = builtins.readFile ./auditor.sh;
}