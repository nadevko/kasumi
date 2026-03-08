{ lib }:
let
  inherit (lib.strings) toInt;
  inherit (lib.trivial) compare min id;
  inherit (lib.attrs) mapAttrs attrNames attrValues;

  inherit (builtins)
    head
    tail
    length
    isList
    elemAt
    concatLists
    filter
    elem
    genList
    groupBy
    sort
    any
    partition
    split
    ;

  inherit (lib.lists)
    concatMap
    flatten
    foldl'
    findFirstIndex
    foldl
    zipListsWith
    listDfs
    toposort
    reverseList
    compareLists
    drop
    take
    hasPrefix
    unique
    ;
in
{
  ifilter0 =
    ipred: input:
    map (idx: elemAt input idx) (
      filter (idx: ipred idx (elemAt input idx)) (genList (i: i) (length input))
    );

  flatten = x: if isList x then concatMap (y: flatten y) x else [ x ];

  remove = e: filter (x: x != e);

  findSingle =
    pred: default: multiple: xs:
    let
      found = filter pred xs;
      len = length found;
    in
    if len == 0 then
      default
    else if len != 1 then
      multiple
    else
      head found;

  findFirstIndex =
    pred: default: xs:
    let
      # A naive recursive implementation would be much simpler, but
      # would also overflow the evaluator stack. We use `foldl'` as a workaround
      # because it reuses the same stack space, evaluating the function for one
      # element after another. We can't return early, so this means that we
      # sacrifice early cutoff, but that appears to be an acceptable cost. A
      # clever scheme with "exponential search" is possible, but appears over-
      # engineered for now. See https://github.com/NixOS/nixpkgs/pull/235267

      # Invariant:
      # - if index < 0 then el == elemAt list (- index - 1) and all elements before el didn't satisfy pred
      # - if index >= 0 then pred (elemAt list index) and all elements before (elemAt list index) didn't satisfy pred
      #
      # We start with index -1 and the 0'th element of the list, which satisfies the invariant
      resultIdx = foldl' (idx: el: if idx < 0 then if pred el then -idx - 1 else idx - 1 else idx) (
        -1
      ) xs;
    in
    if resultIdx < 0 then default else resultIdx;

  findFirst =
    pred: default: xs:
    let
      idx = findFirstIndex pred null xs;
    in
    if idx == null then default else elemAt xs idx;

  count = pred: foldl' (c: x: if pred x then c + 1 else c) 0;

  range = first: last: if first > last then [ ] else genList (i: first + i) (last - first + 1);

  groupBy' =
    op: nul: pred: lst:
    mapAttrs (name: foldl op nul) (groupBy pred lst);

  zipListsWith =
    f: fst: snd:
    genList (i: f (elemAt fst i) (elemAt snd i)) (min (length fst) (length snd));

  zipLists = zipListsWith (fst: snd: { inherit fst snd; });

  listDfs =
    stopOnCycles: before: xs:
    let
      dfs' =
        us: visited: rest:
        let
          c = filter (x: before x us) visited;
          b = partition (x: before x us) rest;
        in
        if stopOnCycles && (length c > 0) then
          {
            cycle = us;
            loops = c;
            inherit visited rest;
          }
        else if length b.right == 0 then
          # nothing is before us
          {
            minimal = us;
            inherit visited rest;
          }
        else
          # grab the first one before us and continue
          dfs' (head b.right) ([ us ] ++ visited) (tail b.right ++ b.wrong);
    in
    dfs' (head xs) [ ] (tail xs);

  toposort =
    before: xs:
    let
      dfsthis = listDfs true before xs;
      toporest = toposort before (dfsthis.visited ++ dfsthis.rest);
    in
    if length xs < 2 then
      # finish
      { result = xs; }
    else if dfsthis ? cycle then
      # there's a cycle, starting from the current vertex, return it
      {
        cycle = reverseList ([ dfsthis.cycle ] ++ dfsthis.visited);
        inherit (dfsthis) loops;
      }
    else if toporest ? cycle then
      # there's a cycle somewhere else in the graph, return it
      toporest
    # Slow, but short. Can be made a bit faster with an explicit stack.
    else
      # there are no cycles
      { result = [ dfsthis.minimal ] ++ toporest.result; };

  sortOn =
    f: xs:
    let
      # Heterogenous list as pair may be ugly, but requires minimal allocations.
      pairs = map (x: [
        (f x)
        x
      ]) xs;
    in
    map (x: elemAt x 1) (
      sort
        # Compare the first element of the pairs
        # Do not factor out the `<`, to avoid calls in hot code; duplicate instead.
        (a: b: head a < head b)
        pairs
    );

  compareLists =
    cmp: a: b:
    if a == [ ] then
      if b == [ ] then 0 else -1
    else if b == [ ] then
      1
    else
      let
        rel = cmp (head a) (head b);
      in
      if rel == 0 then compareLists cmp (tail a) (tail b) else rel;

  naturalSort =
    lst:
    let
      vectorise = s: map (x: if isList x then toInt (head x) else x) (split "(0|[1-9][0-9]*)" s);
      prepared = map (x: [
        (vectorise x)
        x
      ]) lst; # remember vectorised version for O(n) regex splits
      less = a: b: (compareLists compare (head a) (head b)) < 0;
    in
    map (x: elemAt x 1) (sort less prepared);

  hasPrefix = a: b: take (length a) b == a;

  removePrefix =
    a: b:
    if hasPrefix a b then
      drop (length a) b
    else
      throw "lib.lists.removePrefix: First argument is not a list prefix of the second argument";

  commonPrefix =
    a: b:
    let
      # Zip the lists together into a list of booleans whether each element matches
      matchings = zipListsWith (fst: snd: fst != snd) a b;
      # Find the first index where the elements don't match,
      # which will then also be the length of the common prefix.
      # If all elements match, we fall back to the length of the zipped list,
      # which is the same as the length of the smaller list.
      commonPrefixLength = findFirstIndex id (length matchings) matchings;
    in
    take commonPrefixLength a;

  crossLists = f: foldl (fs: args: concatMap (f: map f args) fs) [ f ];

  unique = foldl' (acc: e: if elem e acc then acc else acc ++ [ e ]) [ ];

  uniqueStrings = xs: attrNames (groupBy id xs);

  allUnique = xs: (length (unique xs) == length xs);

  intersectLists = e: filter (x: elem x e);

  subtractLists = e: filter (x: !(elem x e));

  mutuallyExclusive = a: b: length a == 0 || !(any (x: elem x a) b);

  concatAttrValues = set: concatLists (attrValues set);

  replaceElemAt =
    xs: idx: new:
    assert lib.assertMsg (idx >= 0 && idx < length xs)
      "'lists.replaceElemAt' called with index ${toString idx} on a list of size ${toString (length xs)}";
    genList (i: if i == idx then new else elemAt xs i) (length xs);
}
