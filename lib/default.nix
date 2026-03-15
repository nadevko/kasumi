{
  primops ? import ../primops { },
  ...
}:
let
  lib = import ./overlay.nix lib primops;
  self = lib.sets.pointwisel primops <| import ./overlay.nix self primops;
in
self
