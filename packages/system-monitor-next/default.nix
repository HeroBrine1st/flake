{gnomeExtensions}: gnomeExtensions.system-monitor-next.overrideAttrs (old: {
  patches = old.patches ++ [
    ./usr-bin-env.patch
  ];
})