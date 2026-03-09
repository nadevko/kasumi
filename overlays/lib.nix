final: prev:
let
  attrs = import ../lib/attrs.nix final prev;
  debug = import ../lib/debug.nix final prev;
  lists = import ../lib/lists.nix final prev;
  meta = import ../lib/meta.nix final prev;
  numeric = import ../lib/numeric.nix final prev;
  prelude = import ../lib/prelude.nix final prev;
  runtime = import ../lib/runtime.nix final prev;
  strings = import ../lib/strings.nix final prev;
  types = import ../lib/types.nix final prev;
in
{
  inherit
    attrs
    debug
    lists
    meta
    numeric
    prelude
    runtime
    strings
    types
    ;
}
