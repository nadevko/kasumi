final: prev:
let
  inherit (final.lists) foldl';

  inherit (final.prelude) fapply flip pipe;
in
prev.prelude or { }
// {
  # --- realisation -----------------------------------------------------------
  id = x: x;
  const = x: _: x;
  snd = _: y: y;

  apply = f: x: f x;
  fapply = x: f: f x;

  flip =
    f: a: b:
    f b a;
  compose =
    f: g: x:
    f <| g x;

  pipe = foldl' fapply;
  fpipe = flip pipe;

  # --- language operators ----------------------------------------------------
  update = x: y: x // y;
  concat = x: y: x ++ y;
  eq = a: b: a == b;
  neq = a: b: a != b;

  boolNot = x: !x;
  boolOr = a: b: a || b;
  boolAnd = a: b: a && b;
  boolXor = a: b: (!a) != (!b);
  boolImply = a: b: a -> b;

  # --- if statement & basic optionals ----------------------------------------
  ifElse =
    bool: yes: no:
    if bool then yes else no;
  boolAs =
    yes: no: bool:
    if bool then yes else no;

  mayApply = f: maybe: if maybe == null then maybe else f maybe;
  withDefault = default: maybe: if maybe == null then default else maybe;

  # --- basic fixpoints (tying the knot) --------------------------------------
  fix =
    rattrs:
    let
      self = rattrs self;
    in
    self;

  fix' =
    rattrs:
    let
      self = rattrs self // {
        inherit rattrs;
      };
    in
    self;
}
