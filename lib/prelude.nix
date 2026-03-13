final: prev:
let
  inherit (final.lists) foldl' elem all;

  inherit (final.prelude)
    bind
    fapply
    fixWith
    flip
    import
    isFunction
    isFunctionLike
    isFunctor
    isList
    isPath
    isPathLike
    isString
    isStringAble
    isStringLike
    null
    pipe
    typeOf
    ;
in
{
  # --- combinators -----------------------------------------------------------
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

  ifElse =
    pred: f: g: x:
    if pred x then f x else g x;
  boolAs =
    yes: no: cond:
    if cond then yes else no;

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

  attr = name: set: set ? ${name};
  getWith =
    default: name: set:
    set.${name} or default;

  # --- optionals -------------------------------------------------------------
  bind = f: maybe: if maybe == null then null else f maybe;
  do = foldl' (flip bind);
  withDefault = default: maybe: if maybe == null then default else maybe;
  alt =
    f: y: x:
    let
      x' = f x;
    in
    if x' == null then f y else x';

  # --- type predicates -------------------------------------------------------
  isPathLike = x: isPath x || x ? outPath;

  isFunctionLike = f: isFunction f || isFunctor f;
  isFunctor = f: f ? __functor;

  isStringLike = x: isString x || isPathLike x || x ? __toString;
  isStringAble =
    x:
    isStringLike x
    || isList x && all isStringAble x
    || elem (typeOf x) [
      "null"
      "int"
      "float"
      "bool"
    ];

  # --- coercion --------------------------------------------------------------
  invoke = f: if isFunctionLike f then f else import f;
  toFunctionLike = f: if isFunctionLike f then f else _: f;
  toFunctor = f: if isFunctor f then f else { __functor = _: f; };
  toFunction =
    f:
    if isFunction f then
      f
    else if isFunctor f then
      f f
    else
      _: f;

  # --- fixpoints -------------------------------------------------------------
  fixWith =
    name: rattrs:
    let
      self = rattrs self // {
        ${name} = rattrs;
      };
    in
    self;

  fix = fixWith null;
  fixate = fixWith "rattrs";
}
