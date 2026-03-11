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
    ).attrs.pointwiseL
      lib
      (import ./overlay.nix self lib);
in
self
