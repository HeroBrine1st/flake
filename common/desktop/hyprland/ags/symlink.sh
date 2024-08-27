#!/usr/bin/env bash

dir="$(nix-store -r "$(which ags)" 2>/dev/null)/share/com.github.Aylur.ags/types"

test -d "$dir" && rm config/types && ln -s "$dir" config/types