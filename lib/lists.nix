final: prev:
let
  inherit (builtins)
    length
    filter
    listToAttrs
    elemAt
    isList
    genList
    sublist
    ;

  inherit (final.trivial) flip;
  inherit (final.numeric) max clamp;
  inherit (final.attrs) pair;
  inherit (final.debug) throwIf;

  inherit (final.lists) take drop;
in
{
  # --- trivial ---------------------------------------------------------------
  singleton = x: [ x ];
  toList = x: if isList x then x else [ x ];
  optional = cond: x: if cond then [ x ] else [ ];
  optionals = cond: xs: if cond then xs else [ ];

  # --- getters ---------------------------------------------------------------
  take = sublist 0;
  takeR = n: xs: drop (max 0 (length xs - n)) xs;
  drop = n: xs: sublist n (length xs) xs;
  dropR = n: xs: take (max 0 (length xs - n)) xs;

  last =
    xs:
    assert throwIf (xs == [ ]) "kasumi.lib.lists.last: list must not be empty!";
    elemAt xs (length xs - 1);

  init =
    xs:
    assert throwIf (xs == [ ]) "kasumi.lib.lists.init: list must not be empty!";
    take (length xs - 1) xs;

  sublist =
    start: count: xs:
    length xs - start |> clamp 0 count |> genList (i: elemAt xs <| i + start);

  # --- generators ------------------------------------------------------------
  replicate = n: x: genList (_: x) n;

  # --- mutations -------------------------------------------------------------
  reverse =
    xs:
    let
      len = length xs;
    in
    genList (i: elemAt xs (len - i - 1)) len;

  # --- maps ------------------------------------------------------------------
  for = flip map;
  imap0 = f: xs: genList (i: f i <| elemAt xs i) <| length xs;
  imap1 = f: xs: genList (i: f (i + 1) <| elemAt xs i) <| length xs;

  # --- folds -----------------------------------------------------------------
  fold =
    f: nil: xs:
    let
      folder = n: if n == -1 then nil else f (folder <| n - 1) <| elemAt xs n;
    in
    folder <| length xs - 1;

  foldR =
    f: nil: xs:
    let
      len = length xs;
      folder = n: if n == len then nil else n + 1 |> folder |> f (elemAt xs n);
    in
    folder 0;

  dfold =
    transform: getInitial: getFinal: xs:
    let
      len = length xs;
      linkStage =
        previousStage: idx:
        if idx == len then
          getFinal previousStage
        else
          let
            thisStage = transform previousStage (elemAt xs idx) nextStage;
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
      len = length xs;
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
        idx = target |> map (e: pair (toString e) null) |> listToAttrs;
      in
      filter (e: idx ? "${toString e}") base;

  subtractStrings =
    minuend: subtrahend:
    if subtrahend == [ ] then
      minuend
    else
      let
        idx = subtrahend |> map (e: pair (toString e) null) |> listToAttrs;
      in
      filter (e: !idx ? "${toString e}") minuend;
}
