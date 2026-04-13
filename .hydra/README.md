Hydra ssh keys live in hydra home folder, added in .ssh/config like in normal users
It also requires .ssh/known_hosts to be populated

This was deleted from spec.json:

````
"pulls": {
  "type": "githubpulls",
  "value": "HeroBrine1st flake",
  "emailresponsible": false
},
"refs": {
  "type": "github_refs",
  "value": "HeroBrine1st flake heads",
  "emailresponsible": false
},
"githubstatus": {
  "type": "boolean",
  "value": "true"
}
```