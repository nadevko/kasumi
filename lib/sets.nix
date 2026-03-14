final: prev:
let
  inherit (builtins)
    concatMap
    isAttrs
    zipAttrsWith
    listToAttrs
    mapAttrs
    attrNames
    intersectAttrs
    head
    tail
    attrValues
    ;

  inherit (final.lists) singleton;
  inherit (final.trivial) compose id snd;

  inherit (final.sets)
    attr
    pair
    bindAttrs
    singletonPair
    transposeAttrs
    genAttrsBy
    genTransposedAttrsBy
    foldPathWith
    genAttrs
    mapAttrsToList
    mergeAttrsList
    ;
in
prev.attrs or { }
// {
  attr = n: v: { ${n} = v; };
  singletonAttr = n: v: singleton <| attr n v;
  pair = name: value: { inherit name value; };
  singletonPair = n: v: singleton <| pair n v;
  mapValues = f: set: attrValues <| mapAttrs f set;

  bindAttrs = f: set: concatMap (n: f n set.${n}) <| attrNames set;
  mbindAttrs = f: set: listToAttrs <| bindAttrs f set;

  mergeMapAttrs = f: set: attrNames set |> map (n: f n set.${n}) |> mergeAttrsList;

  intersectWith =
    f: left: right:
    mapAttrs (n: f n left.${n}) <| intersectAttrs left right;

  partitionAttrs = pred: set: {
    right = bindAttrs (n: v: if pred n v then singletonPair n v else [ ]) set;
    wrong = bindAttrs (n: v: if !pred n v then singletonPair n v else [ ]) set;
  };

  pointwiseL =
    base: augment:
    base
    // mapAttrs (
      n: v: if isAttrs v && isAttrs (base.${n} or null) then v // base.${n} else base.${n} or v
    ) augment;

  pointwiseR =
    base: override:
    base
    // mapAttrs (n: v: if isAttrs v && isAttrs (base.${n} or null) then base.${n} // v else v) override;

  transposeAttrs =
    set: zipAttrsWith (_: listToAttrs) <| mapAttrsToList (root: mapAttrs (_: pair root)) set;

  genAttrsBy =
    adapter: roots: generator:
    genAttrs roots <| compose generator adapter;

  genTransposedAttrsBy =
    adapter: roots: generator:
    transposeAttrs <| genAttrsBy adapter roots generator;

  genTransposedAttrs = genTransposedAttrsBy id;

  foldPathWith =
    f: default: pattern:
    let
      recurse =
        deepest: nodesPath: set:
        if isAttrs set -> nodesPath == [ ] then
          deepest
        else
          let
            nextDeepest = if set ? ${pattern} then f deepest set.${pattern} else deepest;
            nextSet = set.${head nodesPath} or null;
          in
          if nextSet == null then nextDeepest else recurse nextDeepest (tail nodesPath) nextSet;
    in
    recurse default;

  foldPath = foldPathWith snd;
}
