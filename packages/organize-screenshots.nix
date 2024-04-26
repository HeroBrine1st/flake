{ config, lib, pkgs, ... }: pkgs.writeShellApplication {
    runtimeInputs = [ pkgs.coreutils ];
    name = "organize-screenshots.sh";
    text = ''
#!/bin/bash

set -e

SOURCE_DIR=~/"Pictures/Screenshots"
DEST_DIR=~/"Pictures/Screenshots"

for screenshot in "$SOURCE_DIR"/*.png; do
    timestamp=$(stat -c %Y "$screenshot")

    dir="$DEST_DIR/$(date -d @"$timestamp" +"%Y/%B/%A, %b %d")"
    #echo "$screenshot -> $dir/$(basename "$screenshot")"
    mkdir -p "$dir"
    mv -v "$screenshot" "$dir"
done

find "$DEST_DIR" -depth -type d -execdir sh -c 'touch "$PWD/$0" -r "$PWD/$0/$( ls -t "$PWD/$0" | head -n 1 )"' {} \;
#PATH=$(echo "$PATH" | sed 's|~/.local/bin:||') find "$DEST_DIR" -depth -type d -execdir sh -c 'touch "$PWD/$0" -r "$PWD/$0/$( ls -t "$PWD/$0" | head -n 1 )"' {} \;

'';
}
