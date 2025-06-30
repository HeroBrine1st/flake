{
  yq-go,
  writeShellApplication,
  nebula,

  # Params
  configAppendixFile
}: writeShellApplication {
  name = "nebula";
  text = ''
    # assertions
    [[ "$#" -eq 2 ]]
    [[ "$1" == "-config" ]]
    exec ${nebula}/bin/nebula -config <(${yq-go}/bin/yq '. *+ load("${configAppendixFile}")' "$2")
  '';
}