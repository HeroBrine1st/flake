This should solve /var/lib/private having invalid permissions. 
Credits to https://github.com/nix-community/impermanence/issues/254#issuecomment-2683859091

To be added in common impermanence module

```nix
{
  system.activationScripts."createPersistentStorageDirs".deps = [ "var-lib-private-permissions" "users" "groups" ];
  system.activationScripts = {
    "var-lib-private-permissions" = {
      deps = [ "specialfs" ];
      text = ''
        mkdir -p /persist/var/lib/private
        chmod 0700 /persist/var/lib/private
      '';
    };
  };
}
```