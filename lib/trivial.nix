final: _:
let
  inherit (builtins)
    foldl'
    isFunction
    readFile
    fromJSON
    getEnv
    ;

  inherit (final.trivial)
    fapply
    flip
    compose
    pipe
    boolAs
    isFunctor
    isImpure
    ;
in
{
  id = x: x;
  const = x: _: x;
  snd = _: y: y;

  apply = f: x: f x;
  fapply = x: f: f x;
  concat = x: y: x ++ y;
  update = x: y: x // y;

  flip =
    f: a: b:
    f b a;
  compose =
    f: g: x:
    f <| g x;
  pipe = foldl' fapply;
  fpipe = flip pipe;

  eq = a: b: a == b;
  neq = a: b: a != b;

  boolNot = x: !x;
  boolOr = a: b: a || b;
  boolAnd = a: b: a && b;
  boolXor = a: b: (!a) != (!b);
  boolImply = a: b: a -> b;

  boolAs =
    yes: no: bool:
    if bool then yes else no;
  boolAsTrue = boolAs "true" "false";
  boolAsYes = boolAs "yes" "no";

  ifElse =
    bool: yes: no:
    if bool then yes else no;
  withDefault = default: maybe: if maybe == null then default else maybe;
  applyNullable = f: maybe: if maybe == null then maybe else f maybe;

  invoke = f: if isFunction f then f else import f;
  importJSON = compose fromJSON readFile;
  importTOML = compose fromTOML readFile;

  isAppliable = f: isFunction f || isFunctor f;
  isFunctor = f: f ? __functor && isFunction (f.__functor f);

  toFunction = v: if isFunction v then v else _: v;
  toFunctor = v: if isFunctor v then v else { __functor = _: v; };

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

  isNixShellImpure = getEnv "IN_NIX_SHELL" != "";
  isImpure = builtins ? currentSystem;
  isPure = !isImpure;
}
