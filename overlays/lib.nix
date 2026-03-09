final: prev:
let
  prelude = import ../lib/prelude.nix final prev;
  runtime = import ../lib/runtime.nix final prev;
  versions = import ../lib/versions.nix final prev;
in
{
  inherit prelude runtime versions;
}
