final: prev:
let
  inherit (final.types) isFunction isFunctor;
in
{
  isAppliable = f: isFunction f || isFunctor f;
  isFunctor = f: f ? __functor && isFunction (f.__functor f);

  toFunction = v: if isFunction v then v else _: v;
  toFunctor = v: if isFunctor v then v else { __functor = _: v; };
}
