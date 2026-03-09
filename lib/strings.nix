final: prev:
let
  inherit (final.prelude) boolAs;
in
{
  boolAsTrue = boolAs "true" "false";
  boolAsYes = boolAs "yes" "no";
}
