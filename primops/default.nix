{ lib ? import ../compat { }
, ...
}:
let self = import ./overlay.nix self lib; in
self
