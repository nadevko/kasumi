{
  lib ? import ../primops { },
  ...
}:
let
  self =
    (
      let
        self = import ./overlay.nix self lib;
      in
      self
    ).sets.pointwiseL
      lib
      (import ./overlay.nix self lib);
in
self
