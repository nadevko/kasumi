final: prev:
let
  inherit (final.prelude)
    compare
    compose
    flip
    id
    isList
    ;
  inherit (final.numeric)
    clamp
    div
    max
    min
    toInt
    ;
  inherit (final.sets)
    pair
    assocPairs
    get
    namesOf
    ;
  inherit (final.strings) splits;

  inherit (final.lists)
    any
    at
    binarySearch
    compareFirst
    compareFirstBy
    concatMap
    contains
    countOf
    drop
    findIndex
    flatten
    foldl'
    generate
    groupBy
    hasStart
    headOf
    indices
    singleton
    sortBy
    sublist
    tail
    take
    where
    zipCount
    ;
in
{
  # --- trivial ---------------------------------------------------------------
  singleton = x: [ x ];
  toList = x: if isList x then x else [ x ];
  optional = bool: x: if bool then [ x ] else [ ];
  optionals = bool: xs: if bool then xs else [ ];

  # --- counts ----------------------------------------------------------------
  zipCount = left: right: min (countOf left) (countOf right);
  countBy = pred: foldl' (acc: x: if pred x then acc + 1 else acc) 0;

  # --- getters ---------------------------------------------------------------
  take = sublist 0;
  taker = n: xs: drop (max 0 (countOf xs - n)) xs;
  drop = n: xs: sublist n (countOf xs) xs;
  dropr = n: xs: take (max 0 (countOf xs - n)) xs;

  lastOf =
    xs:
    assert xs != [ ] || throw "kasumi.lists.lastOf: list must not be empty!";
    at (countOf xs - 1) xs;
  initOf =
    xs:
    assert xs != [ ] || throw "kasumi.lists.init: list must not be empty!";
    take (countOf xs - 1) xs;
  sublist =
    from: count: xs:
    countOf xs - from |> clamp 0 count |> generate (i: at (i + from) xs);

  zipStarts =
    xs: ys:
    let
      count = zipCount xs ys;
    in
    take (findIndex (i: at i xs != at i ys) count <| indices count) xs;

  binarySearch =
    pred: lo: hi:
    if lo >= hi then
      lo
    else
      let
        mid = div (lo + (hi - lo)) 2;
      in
      if pred mid then binarySearch pred lo mid else binarySearch pred (mid + 1) hi;
  findIndex =
    pred: default: xs:
    let
      count = countOf xs;

      recurse =
        curr: step:
        if curr >= count then
          [
            count
            count
          ]
        else if pred <| at curr xs then
          [
            curr
            (curr + 1)
          ]
        else
          recurse (curr + step) (step * 2);

      range = recurse 0 1;
      idx = binarySearch (i: pred (at i xs)) (headOf range) (at 1 range);
    in
    if idx >= count then default else idx;

  findFirst =
    pred: default: xs:
    let
      index = findIndex pred null xs;
    in
    if index == null then default else at index xs;

  splitAt =
    i: xs:
    let
      count = countOf xs;
      safeIdx = clamp 0 count (if i < 0 then count + i else i);
    in
    {
      left = take safeIdx xs;
      right = drop safeIdx xs;
    };

  # --- checks ----------------------------------------------------------------
  hasStart = start: xs: take (countOf start) xs == start;

  # --- maps ------------------------------------------------------------------
  for = flip map;
  imap0 = f: xs: generate (i: f i <| at i xs) <| countOf xs;
  imap1 = f: xs: generate (i: f (i + 1) <| at i xs) <| countOf xs;
  zipBy =
    f: left: right:
    generate (i: f (at i left) (at i right)) <| zipCount left right;

  # --- folders ---------------------------------------------------------------
  foldl =
    f: nil: xs:
    let
      fold = n: if n == -1 then nil else f (fold <| n - 1) <| at n xs;
    in
    fold <| countOf xs - 1;

  foldr =
    f: nil: xs:
    let
      count = countOf xs;
      fold = n: if n == count then nil else n + 1 |> fold |> f (at xs n);
    in
    fold 0;

  dfold =
    transform: getInitial: getFinal: xs:
    let
      count = countOf xs;
      linkStage =
        previousStage: idx:
        if idx == count then
          getFinal previousStage
        else
          let
            thisStage = transform previousStage (at xs idx) nextStage;
            nextStage = linkStage thisStage <| idx + 1;
          in
          thisStage;
      initialStage = getInitial firstStage;
      firstStage = linkStage initialStage 0;
    in
    firstStage;

  # --- sorts -----------------------------------------------------------------
  sortOn =
    f: xs:
    map (x: [
      (f x)
      x
    ]) xs
    |> sortBy (a: b: headOf a < headOf b)
    |> map (at 1);

  compareFirstBy =
    cmp: a: b:
    let
      countA = countOf a;
      countB = countOf b;
      idx =
        findIndex (i: cmp (at i a) (at i b) != 0) null
        <| indices (if countA < countB then countA else countB);
    in
    if idx == null then compare countA countB else cmp (at idx a) (at idx b);
  compareFirst = compareFirstBy compare;

  naturalSort =
    xs:
    map (value: {
      vec = map (x: if isList x then toInt <| headOf x else x) <| splits "(0|[1-9][0-9]*)" value;
      inherit value;
    }) xs
    |> sortBy (a: b: (compareFirst a.vec b.vec) < 0)
    |> map (get "value");

  # --- mutations -------------------------------------------------------------
  reverse =
    xs:
    let
      count = countOf xs;
    in
    generate (i: at (count - i - 1) xs) count;

  flatten = x: if isList x then concatMap flatten x else [ x ];

  replaceAt =
    xs: idx: y:
    assert
      0 <= idx && idx < countOf xs
      || throw "kasumi.lists.replaceAt: called with index ${toString idx} on a list of size ${toString <| countOf xs}";
    generate (i: if i == idx then y else at i xs) <| countOf xs;
  removeStart =
    start: xs:
    assert
      hasStart start xs
      || throw "kasumi.lists.removeStart: First argument is not a list prefix of the second argument";
    drop (countOf start) xs;

  intersperse =
    sep: xs:
    if xs == [ ] then
      [ ]
    else
      singleton (headOf xs)
      ++ concatMap (x: [
        sep
        x
      ]) (tail xs);

  # --- generators ------------------------------------------------------------
  replicate = n: x: generate (_: x) n;
  indices = generate id;

  rangeIn = from: to: generate (i: from + i) (to - from + 1);
  rangeInStep =
    from: to: step:
    let
      count = div (to - from) step + 1;
    in
    generate (i: from + i * step) count;
  rangeInStepInclusive =
    from: to: step:
    let
      count = div (to - from + step) step;
    in
    generate (i: from + i * step) count;

  # --- set operations --------------------------------------------------------
  isListsIntersect = xs: ys: countOf xs != 0 && any (contains xs) ys;
  intersectLists = compose where contains;
  intersectStrings =
    base: target:
    if target == [ ] then
      [ ]
    else
      let
        idx = target |> map (x: pair (toString x) null) |> assocPairs;
      in
      where (x: idx ? "${toString x}") base;

  subtractLists = xs: where (x: !contains xs x);
  subtractStrings =
    minuend: subtrahend:
    if subtrahend == [ ] then
      minuend
    else
      let
        idx = subtrahend |> map (x: pair (toString x) null) |> assocPairs;
      in
      where (x: !idx ? "${toString x}") minuend;

  isAllUnique = xs: !any (contains xs) xs;
  unique = xs: where (contains xs) xs;
  uniqueStrings = xs: namesOf (groupBy id xs);
}
