{ lib }:
let
  inherit (lib.strings) toInt;
  inherit (lib.trivial)
    compare
    min
    id
    warn
    ;
  inherit (lib.attrsets) mapAttrs attrNames attrValues;
  inherit (lib) max;
in
rec {

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
    map
    ;

  singleton = x: [ x ];

  forEach = xs: f: map f xs;

  foldr =
    op: nul: list:
    let
      len = length list;
      fold' = n: if n == len then nul else op (elemAt list n) (fold' (n + 1));
    in
    fold' 0;

  fold = warn "fold has been deprecated, use foldr instead" foldr;

  foldl =
    op: nul: list:
    let
      foldl' = n: if n == -1 then nul else op (foldl' (n - 1)) (elemAt list n);
    in
    foldl' (length list - 1);

  foldl' =
    op: acc:
    # The builtin `foldl'` is a bit lazier than one might expect.
    # See https://github.com/NixOS/nix/pull/7158.
    # In particular, the initial accumulator value is not forced before the first iteration starts.
    builtins.seq acc (builtins.foldl' op acc);

  imap0 = f: list: genList (n: f n (elemAt list n)) (length list);

  imap1 = f: list: genList (n: f (n + 1) (elemAt list n)) (length list);

  ifilter0 =
    ipred: input:
    map (idx: elemAt input idx) (
      filter (idx: ipred idx (elemAt input idx)) (genList (x: x) (length input))
    );

  concatMap = builtins.concatMap;

  flatten = x: if isList x then concatMap (y: flatten y) x else [ x ];

  remove = e: filter (x: x != e);

  findSingle =
    pred: default: multiple: list:
    let
      found = filter pred list;
      len = length found;
    in
    if len == 0 then
      default
    else if len != 1 then
      multiple
    else
      head found;

  findFirstIndex =
    pred: default: list:
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
      resultIndex = foldl' (
        index: el:
        if index < 0 then
          # No match yet before the current index, we need to check the element
          if pred el then
            # We have a match! Turn it into the actual index to prevent future iterations from modifying it
            -index - 1
          else
            # Still no match, update the index to the next element (we're counting down, so minus one)
            index - 1
        else
          # There's already a match, propagate the index without evaluating anything
          index
      ) (-1) list;
    in
    if resultIndex < 0 then default else resultIndex;

  findFirst =
    pred: default: list:
    let
      index = findFirstIndex pred null list;
    in
    if index == null then default else elemAt list index;

  any = builtins.any;

  all = builtins.all;

  count = pred: foldl' (c: x: if pred x then c + 1 else c) 0;

  optional = cond: elem: if cond then [ elem ] else [ ];

  optionals = cond: elems: if cond then elems else [ ];

  toList = x: if isList x then x else [ x ];

  range = first: last: if first > last then [ ] else genList (n: first + n) (last - first + 1);

  replicate = n: elem: genList (_: elem) n;

  partition = builtins.partition;

  groupBy' =
    op: nul: pred: lst:
    mapAttrs (name: foldl op nul) (groupBy pred lst);

  groupBy =
    builtins.groupBy or (
      pred:
      foldl' (
        r: e:
        let
          key = pred e;
        in
        r // { ${key} = (r.${key} or [ ]) ++ [ e ]; }
      ) { }
    );

  zipListsWith =
    f: fst: snd:
    genList (n: f (elemAt fst n) (elemAt snd n)) (min (length fst) (length snd));

  zipLists = zipListsWith (fst: snd: { inherit fst snd; });

  reverseList =
    xs:
    let
      l = length xs;
    in
    genList (n: elemAt xs (l - n - 1)) l;

  listDfs =
    stopOnCycles: before: list:
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
    dfs' (head list) [ ] (tail list);

  toposort =
    before: list:
    let
      dfsthis = listDfs true before list;
      toporest = toposort before (dfsthis.visited ++ dfsthis.rest);
    in
    if length list < 2 then
      # finish
      { result = list; }
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

  sort = builtins.sort;

  sortOn =
    f: list:
    let
      # Heterogenous list as pair may be ugly, but requires minimal allocations.
      pairs = map (x: [
        (f x)
        x
      ]) list;
    in
    map (x: builtins.elemAt x 1) (
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
      vectorise = s: map (x: if isList x then toInt (head x) else x) (builtins.split "(0|[1-9][0-9]*)" s);
      prepared = map (x: [
        (vectorise x)
        x
      ]) lst; # remember vectorised version for O(n) regex splits
      less = a: b: (compareLists compare (head a) (head b)) < 0;
    in
    map (x: elemAt x 1) (sort less prepared);

  take = count: sublist 0 count;

  takeEnd = n: xs: drop (max 0 (length xs - n)) xs;

  drop = count: list: sublist count (length list) list;

  dropEnd = n: xs: take (max 0 (length xs - n)) xs;

  hasPrefix = list1: list2: take (length list1) list2 == list1;

  removePrefix =
    list1: list2:
    if hasPrefix list1 list2 then
      drop (length list1) list2
    else
      throw "lib.lists.removePrefix: First argument is not a list prefix of the second argument";

  sublist =
    start: count: list:
    let
      len = length list;
    in
    genList (n: elemAt list (n + start)) (
      if start >= len then
        0
      else if start + count > len then
        len - start
      else
        count
    );

  commonPrefix =
    list1: list2:
    let
      # Zip the lists together into a list of booleans whether each element matches
      matchings = zipListsWith (fst: snd: fst != snd) list1 list2;
      # Find the first index where the elements don't match,
      # which will then also be the length of the common prefix.
      # If all elements match, we fall back to the length of the zipped list,
      # which is the same as the length of the smaller list.
      commonPrefixLength = findFirstIndex id (length matchings) matchings;
    in
    take commonPrefixLength list1;

  last =
    list:
    assert lib.assertMsg (list != [ ]) "lists.last: list must not be empty!";
    elemAt list (length list - 1);

  init =
    list:
    assert lib.assertMsg (list != [ ]) "lists.init: list must not be empty!";
    take (length list - 1) list;

  crossLists = f: foldl (fs: args: concatMap (f: map f args) fs) [ f ];

  unique = foldl' (acc: e: if elem e acc then acc else acc ++ [ e ]) [ ];

  uniqueStrings = list: attrNames (groupBy id list);

  allUnique = list: (length (unique list) == length list);

  intersectLists = e: filter (x: elem x e);

  subtractLists = e: filter (x: !(elem x e));

  mutuallyExclusive = a: b: length a == 0 || !(any (x: elem x a) b);

  concatAttrValues = set: concatLists (attrValues set);

  replaceElemAt =
    list: idx: newElem:
    assert lib.assertMsg (idx >= 0 && idx < length list)
      "'lists.replaceElemAt' called with index ${toString idx} on a list of size ${toString (length list)}";
    genList (i: if i == idx then newElem else elemAt list i) (length list);
}
