final: prev:
let
  lists = import ../lib/lists.nix final prev;
  numeric = import ../lib/numeric.nix final prev;
  prelude = import ../lib/prelude.nix final prev;
  runtime = import ../lib/runtime.nix final prev;
  strings = import ../lib/strings/default.nix final prev;
  versions = import ../lib/versions.nix final prev;
in
{
  inherit
    lists
    numeric
    prelude
    runtime
    strings
    versions
    ;
}
