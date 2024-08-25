#!/usr/bin/env bash

test -d "$(nix-store -r "$(which ags)" 2>/dev/null)/share/com.github.Aylur.ags/types" && \
  rm ags/types && \
  ln -s "$(nix-store -r "$(which ags)" 2>/dev/null)/share/com.github.Aylur.ags/types" ags/types