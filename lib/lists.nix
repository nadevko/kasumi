final: prev:
let
  inherit (final.prelude) flip;
  inherit (final.types) isList;
  inherit (final.numeric) max clamp;
  inherit (final.attrs) pair fromPairs;

  inherit (final.lists)
    take
    drop
    at
    size
    filter
    generate
    sublist
    concatMap
    tail
    head
    singleton
    ;
in
prev.lists or { }
// {
  # --- trivial ---------------------------------------------------------------
  singleton = x: [ x ];
  toList = x: if isList x then x else [ x ];
  optional = cond: x: if cond then [ x ] else [ ];
  optionals = cond: xs: if cond then xs else [ ];

  # --- getters ---------------------------------------------------------------
  take = sublist 0;
  takeR = n: xs: drop (max 0 (size xs - n)) xs;
  drop = n: xs: sublist n (size xs) xs;
  dropR = n: xs: take (max 0 (size xs - n)) xs;

  last =
    xs:
    assert xs != [ ] || "kasumi.lists.last: list must not be empty!";
    at xs (size xs - 1);

  init =
    xs:
    assert xs != [ ] || "kasumi.lists.init: list must not be empty!";
    take (size xs - 1) xs;

  sublist =
    start: count: xs:
    size xs - start |> clamp 0 count |> generate (i: at xs <| i + start);

  # --- generators ------------------------------------------------------------
  replicate = n: x: generate (_: x) n;
  range = from: to: if from > to then [ ] else generate (i: from + i) (to - from + 1);

  intersperse =
    sep: xs:
    if xs == [ ] then
      [ ]
    else
      singleton (head xs)
      ++ concatMap (x: [
        sep
        x
      ]) (tail xs);

  # --- mutations -------------------------------------------------------------
  reverse =
    xs:
    let
      len = size xs;
    in
    generate (i: at xs (len - i - 1)) len;

  # --- maps ------------------------------------------------------------------
  for = flip map;
  imap0 = f: xs: generate (i: f i <| at xs i) <| size xs;
  imap1 = f: xs: generate (i: f (i + 1) <| at xs i) <| size xs;

  # --- folds -----------------------------------------------------------------
  fold =
    f: nil: xs:
    let
      folder = n: if n == -1 then nil else f (folder <| n - 1) <| at xs n;
    in
    folder <| size xs - 1;

  foldR =
    f: nil: xs:
    let
      len = size xs;
      folder = n: if n == len then nil else n + 1 |> folder |> f (at xs n);
    in
    folder 0;

  dfold =
    transform: getInitial: getFinal: xs:
    let
      len = size xs;
      linkStage =
        previousStage: idx:
        if idx == len then
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

  # --- filters ---------------------------------------------------------------

  # --- sorts -----------------------------------------------------------------

  # --- splits ----------------------------------------------------------------
  splitAt =
    i: xs:
    let
      len = size xs;
      safeIdx = clamp 0 len (if i < 0 then len + i else i);
    in
    {
      left = take safeIdx xs;
      right = drop safeIdx xs;
    };

  # --- set operations --------------------------------------------------------
  intersectStrings =
    base: target:
    if target == [ ] then
      [ ]
    else
      let
        idx = target |> map (e: pair (toString e) null) |> fromPairs;
      in
      filter (e: idx ? "${toString e}") base;

  subtractStrings =
    minuend: subtrahend:
    if subtrahend == [ ] then
      minuend
    else
      let
        idx = subtrahend |> map (e: pair (toString e) null) |> fromPairs;
      in
      filter (e: !idx ? "${toString e}") minuend;
}
