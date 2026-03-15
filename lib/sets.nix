final: prev:
let
  inherit (final.prelude)
    isSet
    compose
    id
    snd
    ;
  inherit (final.lists)
    singleton
    concatMap
    head
    tail
    map
    ;

  inherit (final.sets)
    assocNames
    assocPairs
    attr
    bindSets
    foldPathBy
    genAttrs
    genSetBy
    genTransposedAttrsBy
    groupMap
    intersectr
    listMap
    mapValues
    mergeAttrs
    namesOf
    pair
    pluck
    singletonPair
    transposeAttrs
    valuesOf
    ;
in
{
  # --- primitives ------------------------------------------------------------
  attr = n: v: { ${n} = v; };
  singletonAttr = n: v: singleton <| attr n v;

  pair = name: value: { inherit name value; };
  singletonPair = n: v: singleton <| pair n v;
  swap = p: pair p.value p.name;

  # -- associations -----------------------------------------------------------
  assocBy = f: xs: assocPairs <| map f xs;
  assocNames = f: ns: assocPairs <| map (n: pair n <| f n) ns;
  assocValues = f: vs: assocPairs <| map (v: pair (f v) v) vs;
  assocAttrs = f: x: assocPairs <| listMap f x;

  # --- grouping --------------------------------------------------------------
  groupOf = groupMap snd;
  groupMapOnly =
    ns: f: sets:
    assocPairs <| map (n: pluck n sets |> f n |> pair n) ns;

  # --- lists -----------------------------------------------------------------
  listPairs = listMap pair;
  listMap = f: set: valuesOf <| mapValues f set;
  listOnly = ns: set: map (n: set.${n}) ns;

  # --- updaters --------------------------------------------------------------
  pointwisel =
    base: augment:
    base
    // mapValues (
      n: v: if isSet v && isSet (base.${n} or null) then v // base.${n} else base.${n} or v
    ) augment;

  pointwiser =
    base: override:
    base
    // mapValues (n: v: if isSet v && isSet (base.${n} or null) then base.${n} // v else v) override;

  # --- set -> list -----------------------------------------------------------

  # idk
  mergeMap = f: set: namesOf set |> map (n: f n set.${n}) |> mergeAttrs;
  bindSets = f: set: concatMap (n: f n set.${n}) <| namesOf set;
  mbindSets = f: set: assocPairs <| bindSets f set;

  # --- intersections ---------------------------------------------------------
  intersectWith =
    f: left: right:
    mapValues (n: f n left.${n}) <| intersectr left right;

  partitionSets = pred: set: {
    right = bindSets (n: v: if pred n v then singletonPair n v else [ ]) set;
    wrong = bindSets (n: v: if !pred n v then singletonPair n v else [ ]) set;
  };

  # --- transforms ------------------------------------------------------------
  transposeSet = set: groupMap (_: assocPairs) <| listMap (root: mapValues (_: pair root)) set;

  # --- generators ------------------------------------------------------------
  genSetBy =
    adapter: roots: generator:
    genAttrs roots <| compose generator adapter;

  genTransposedAttrsBy =
    adapter: roots: generator:
    transposeAttrs <| genSetBy adapter roots generator;

  genTransposedAttrs = genTransposedAttrsBy id;

  # --- getters ---------------------------------------------------------------
  pick = ns: set: assocNames (n: set.${n}) ns;

  # --- selections ------------------------------------------------------------
  foldPathBy =
    f: default: pattern:
    let
      recurse =
        deepest: nodesPath: set:
        if isSet set -> nodesPath == [ ] then
          deepest
        else
          let
            nextDeepest = if set ? ${pattern} then f deepest set.${pattern} else deepest;
            nextSet = set.${head nodesPath} or null;
          in
          if nextSet == null then nextDeepest else recurse nextDeepest (tail nodesPath) nextSet;
    in
    recurse default;

  foldPath = foldPathBy snd;
}
