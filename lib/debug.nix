final: prev:
let
  inherit (builtins)
    unsafeGetAttrPos
    warn
    subtractLists
    concatStringsSep
    trace
    ;

  inherit (final.lists) foldr;
  inherit (final.trivial) flip;

  inherit (final.debug) attrPos' throw;
in
{
  validateEnumList =
    msg: valid: given:
    let
      unexpected = subtractLists valid given;
    in
    assert
      unexpected == [ ]
      ||
        throw (msg
        + ": "
        + (concatStringsSep ", " <| map toString unexpected)
        + " unexpected; valid ones: "
        + (concatStringsSep ", " <| map toString valid));
    given;

  info = msg: trace "INFO: ${msg}";
  withWarns = flip <| foldr warn;

  attrPos' =
    default: n: set:
    let
      pos = unsafeGetAttrPos n set;
    in
    if pos == null then default else "${pos.file}:${toString pos.line}:${toString pos.column}";

  attrPos = attrPos' "<unknown location>";
}
