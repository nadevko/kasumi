final: prev:
let
  inherit (builtins)
    unsafeGetAttrPos
    warn
    subtractLists
    concatStringsSep
    trace
    ;

  inherit (prev.lists) foldr;

  inherit (final.trivial) flip;
in
rec {
  warnIf =
    cond: msg: x:
    if cond then warn msg x else x;
  throwIf =
    cond: msg: x:
    if cond then throw msg x else x;
  warnIfNot = cond: warnIf (!cond);
  throwIfNot = cond: throwIf (!cond);

  validateEnumList =
    msg: valid: given:
    let
      unexpected = subtractLists valid given;
    in
    throwIfNot (unexpected == [ ])
    <|
      msg
      + ": "
      + (concatStringsSep ", " <| map toString unexpected)
      + " unexpected; valid ones: "
      + (concatStringsSep ", " <| map toString valid);

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
