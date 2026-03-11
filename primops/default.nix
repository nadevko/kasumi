{
  lib ? import ../shadow { },
  ...
}:
let
  self = import ./overlay.nix self lib;
in
self
