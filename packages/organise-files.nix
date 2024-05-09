{ config, lib, pkgs, ... }: pkgs.writeShellApplication {
  runtimeInputs = [ pkgs.coreutils ];
  name = "organise-files.sh";
  text = ''
    #!/bin/bash

    set -e

    SOURCE_DIR="$1"
    DEST_DIR="$2"

    for file in "$SOURCE_DIR"/*; do
        if [[ -d "$file" ]]; then
          continue
        fi
        timestamp=$(stat -c %Y "$file")

        dir="$DEST_DIR/$(date -d @"$timestamp" +"%Y/%B/%A, %b %d")"
        mkdir -p "$dir"
        mv -v "$file" "$dir"
    done

    find "$DEST_DIR" -depth -type d -execdir sh -c 'touch "$PWD/$0" -r "$PWD/$0/$( ls -t "$PWD/$0" | head -n 1 )"' {} \;
  '';
}
