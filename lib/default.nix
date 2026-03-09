{
  lib ? import ../overlays/builtins.nix { } { },
}:
let
  self = import ../overlays/lib.nix self lib;
in
self
