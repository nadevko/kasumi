{
  lib ? builtins,
  ...
}:
let
  self = import ./overlay.nix self lib;
in
lib // self
