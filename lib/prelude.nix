final: prev:
let
  inherit (final.lists) foldl' contains all;

  inherit (final.prelude)
    applyTo
    bind
    converge
    ensure
    fixAs
    flip
    import
    isFunction
    isFunctor
    isInterpolish
    isLambda
    isList
    isPath
    isPathish
    isString
    isStringable
    null
    pipe
    typeOf
    ;
in
prev.prelude or { }
// {
  # --- combinators -----------------------------------------------------------
  id = x: x;
  const = x: _: x;
  snd = _: y: y;

  flip =
    f: x: y:
    f y x;
  compose =
    f: g: x:
    f <| g x;
  on =
    f: g: x: y:
    f (g x) (g y);
  lift2 =
    f: g: h: x:
    f (g x) (h x);

  ifElse =
    pred: f: g: x:
    if pred x then f x else g x;
  boolAs =
    yes: no: cond:
    if cond then yes else no;
  ensure =
    no: yes: cond:
    if cond then yes else no;

  # --- fixpoints -------------------------------------------------------------
  fixAs =
    name: rset:
    let
      self = rset self // {
        ${name} = rset;
      };
    in
    self;

  fix = fixAs null;
  fixate = fixAs "_rset";

  converge =
    f: x:
    let
      x' = f x;
    in
    if x' == x then x else converge f x';

  # --- language operators ----------------------------------------------------
  update = a: b: a // b;
  concat = a: b: a ++ b;
  append = a: b: a + b;
  eq = a: b: a == b;
  neq = a: b: a != b;

  lnot = x: !x;
  lor = a: b: a || b;
  land = a: b: a && b;
  lxor = a: b: (!a) != (!b);
  limp = a: b: a -> b;

  apply = f: x: f x;
  applyTo = x: f: f x;

  pipe = foldl' applyTo;
  pipeTo = flip pipe;

  tryHas = name: set: set ? ${name};
  getWith =
    default: name: set:
    set.${name} or default;

  # --- optionals -------------------------------------------------------------
  bind = f: maybe: if maybe == null then null else f maybe;
  do = foldl' <| flip bind;
  withDefault = default: maybe: if maybe == null then default else maybe;
  alt =
    f: y: x:
    let
      x' = f x;
    in
    if x' == null then f y else x';

  # --- ensures ---------------------------------------------------------------
  ensureSet = ensure { };
  ensureSingleton = yes: ensure [ ] [ yes ];
  ensureList = ensure [ ];

  # --- type predicates -------------------------------------------------------
  isPathish = x: isPath x || x ? outPath;

  isFunction = f: isLambda f || isFunctor f;
  isFunctor = f: f ? __functor;

  isInterpolish = x: isString x || isPathish x || x ? __toString;
  isStringable =
    x:
    isInterpolish x
    || contains [ "null" "int" "float" "bool" ] (typeOf x)
    || isList x && all isStringable x;

  # --- coercion --------------------------------------------------------------
  invoke = f: if isFunction f then f else import f;
  toFunction = f: if isFunction f then f else _: f;
  toFunctor = f: if isFunctor f then f else { __functor = _: f; };
  toLambda =
    f:
    if isLambda f then
      f
    else if isFunctor f then
      f f
    else
      _: f;
}
