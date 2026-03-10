final: prev:
let
  inherit (final.lists) foldl' elem all;

  inherit (final.prelude)
    fapply
    flip
    isFunction
    isFunctor
    isStr
    isStrLike
    pipe
    typeOf
    isList
    isPath
    isStrCast
    ;
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
    f: x: y:
    f y x;
  compose =
    f: g: x:
    f <| g x;
  on =
    f: g: x: y:
    f (g x) (g y);
  converge =
    f: g: h: x:
    f (g x) (h x);

  pipe = foldl' fapply;
  fpipe = flip pipe;

  # --- language operators ----------------------------------------------------
  update = a: b: a // b;
  concat = a: b: a ++ b;
  eq = a: b: a == b;
  neq = a: b: a != b;

  boolNot = x: !x;
  boolOr = a: b: a || b;
  boolAnd = a: b: a && b;
  boolXor = a: b: (!a) != (!b);
  boolImply = a: b: a -> b;

  # --- if statement & basic optionals ----------------------------------------
  ifElse =
    cond: yes: no:
    if cond then yes else no;
  boolAs =
    yes: no: cond:
    if cond then yes else no;
  choice =
    pred: f: g: x:
    if pred x then f x else g x;

  mayApply = f: maybe: if maybe == null then null else f maybe;
  withDefault = default: maybe: if maybe == null then default else maybe;

  # --- type predicates -------------------------------------------------------
  isAppliable = f: isFunction f || isFunctor f;
  isFunctor = f: f ? __functor && isFunction (f.__functor f);
  isStrLike = x: isStr x || isPath x || x ? outPath || x ? __toString;
  isStrCast =
    x:
    isStrLike x
    || isList x && all isStrCast x
    || elem (typeOf x) [
      "null"
      "int"
      "float"
      "bool"
    ];

  # --- coercion --------------------------------------------------------
  invoke = f: if isFunction f then f else import f;
  toFunction = v: if isFunction v then v else _: v;
  toFunctor = v: if isFunctor v then v else { __functor = _: v; };

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
