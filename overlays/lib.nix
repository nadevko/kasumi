final: prev:
let
  prelude = import ../lib/prelude.nix final prev;
  runtime = import ../lib/runtime.nix final prev;
in
{
  inherit prelude runtime;
}
