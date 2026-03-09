final: prev:
let
  inherit (final.types) isFunction isFunctor;
in
prev.types or { }
// {
  # --- basic validation ------------------------------------------------------
  isAppliable = f: isFunction f || isFunctor f;
  isFunctor = f: f ? __functor && isFunction (f.__functor f);

  # --- basic coercion --------------------------------------------------------
  toFunction = v: if isFunction v then v else _: v;
  toFunctor = v: if isFunctor v then v else { __functor = _: v; };
}
