{ lib, ... }:
rec {

  fix =
    f:
    let
      x = f x;
    in
    x;

  fix' =
    f:
    let
      x = f x // {
        __unfix__ = f;
      };
    in
    x;

  converge =
    f: x:
    let
      x' = f x;
    in
    if x' == x then x else converge f x';

  extends =
    overlay: f:
    # The result should be thought of as a function, the argument of that function is not an argument to `extends` itself
    (
      final:
      let
        prev = f final;
      in
      prev // overlay final prev
    );

  composeExtensions =
    f: g: final: prev:
    let
      fApplied = f final prev;
      prev' = prev // fApplied;
    in
    fApplied // g final prev';

  composeManyExtensions = lib.foldr (x: y: composeExtensions x y) (final: prev: { });

  makeExtensible = makeExtensibleWithCustomName "extend";

  makeExtensibleWithCustomName =
    extenderName: rattrs:
    fix' (
      self:
      (rattrs self)
      // {
        ${extenderName} = f: makeExtensibleWithCustomName extenderName (extends f rattrs);
      }
    );

  toExtension =
    f:
    if lib.isFunction f then
      final: prev:
      let
        fPrev = f prev;
      in
      if lib.isFunction fPrev then
        # f is (final: prev: { ... })
        f final prev
      else
        # f is (prev: { ... })
        fPrev
    else
      # f is not a function; probably { ... }
      final: prev: f;
}
