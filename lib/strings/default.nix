final: prev:
let
  inherit (final.prelude) boolAs neq;
  inherit (final.lists)
    imap1
    filter
    replicate
    at
    range
    minimum
    fold'
    size
    generate
    elem
    ;
  inherit (final.attrs) mapValues;
  inherit (final.types) isPath;
  inherit (final.numeric) min max;
  inherit (final.debug) throwIf;
  inherit (final.strings)
    join
    joinSep
    joinImap1Sep
    joinMapSep
    joinMap
    joinAttrsSep
    joinWhereSep
    joinOptionalsSep
    replaceAll
    length
    slice
    commonPrefixLength
    commonSuffixLength
    levenshtein
    commonSegmentLength
    chars
    ascii-to-num
    num-to-ascii
    charAt
    ;
in
prev.strings or { }
// {
  # --- joins -----------------------------------------------------------------
  join = joinSep "";
  joinLines = xs: joinSep "\n" xs + "\n";

  joinMap = joinMapSep "";
  joinMapSep =
    sep: f: xs:
    map f xs |> joinSep sep;

  joinImap1 = joinImap1Sep "";
  joinImap1Sep =
    sep: f: xs:
    imap1 f xs |> joinSep sep;

  joinWhere = joinWhereSep "";
  joinWhereSep =
    sep: pred: xs:
    filter pred xs |> joinSep sep;

  joinOptionals = joinOptionalsSep "";
  joinOptionalsSep = sep: joinWhereSep sep <| neq "";

  joinAttrs = joinAttrsSep "";
  joinAttrsSep =
    sep: f: attrs:
    joinSep sep <| mapValues f attrs;

  # --- operations on characters ----------------------------------------------
  charAt = x: i: slice i 1 x;
  chars = x: generate (charAt x) <| length x;
  charsMap = f: x: chars x |> joinMap f;

  ascii-to-num = import ./ascii-to-num.nix;
  num-to-ascii = import ./num-to-ascii.nix;
  rfc3986-unreserved = import ./rfc3986-unreserved.nix;

  decodeAscii = x: if ascii-to-num ? ${x} then ascii-to-num.${x} else null;
  encodeAscii = i: if 8 < i && i < 14 || 31 < i && i < 127 then at num-to-ascii i else null;

  # --- generators ------------------------------------------------------------
  repeat = n: x: join <| replicate n x;

  # --- checks ----------------------------------------------------------------
  hasPrefix =
    seg: str:
    throwIf (isPath seg) "kasumi.strings.hasPrefix: only strings are supported."
    <| slice 0 (length seg) str == seg;

  hasSuffix =
    seg: str:
    let
      len = length str;
      segLen = length seg;
    in
    throwIf (isPath seg) "kasumi.strings.hasSuffix: only strings are supported."
    <| len >= segLen && slice (len - segLen) segLen str == seg;

  # --- mutations -------------------------------------------------------------
  replace = from: to: replaceAll [ from ] [ to ];

  # --- escapes ---------------------------------------------------------------

  # --- serialisation (bools) -------------------------------------------------
  optionalStr = str: boolAs str "";

  boolAsTrue = boolAs "true" "false";
  boolAsYes = boolAs "yes" "no";

  # --- metrics ---------------------------------------------------------------
  commonSegmentLength =
    getChar: a: b:
    let
      lenA = length a;
      lenB = length b;
      m = min lenA lenB;
      recurse = i: if i >= m || getChar i a != getChar i b then i else recurse (i + 1);
    in
    recurse 0;

  commonPrefixLength = commonSegmentLength (i: str: slice i 1 str);

  commonSuffixLength = a: b: commonSegmentLength (i: str: slice (length str - i - 1) 1 str) a b;

  levenshtein =
    strA: strB:
    let
      pre = commonPrefixLength strA strB;
      suf = commonSuffixLength strA strB;

      lenA = length strA;
      lenB = length strB;

      pureLenA = max 0 <| lenA - pre - suf;
      pureLenB = max 0 <| lenB - pre - suf;

      trivialDistance =
        if pureLenA == 0 then
          pureLenB
        else if pureLenB == 0 then
          pureLenA
        else
          null;

      charsA = chars <| slice pre pureLenA strA;
      charsB = chars <| slice pre pureLenB strB;

      initialRow = range 0 pureLenB;
      colIndex = range 1 pureLenB;
      rowIndex = range 1 pureLenA;

      folder =
        prevRow: idy:
        fold' (
          rowAcc: idx:
          let
            deletionCost = at prevRow idx;
            substitutionBase = at prevRow (idx - 1);
            insertionCost = at rowAcc (size rowAcc - 1);

            isCharMatch = at charsA (idy - 1) == at charsB (idx - 1);
            cost = if isCharMatch then 0 else 1;

            result = minimum [
              (deletionCost + 1)
              (insertionCost + 1)
              (substitutionBase + cost)
            ];
          in
          rowAcc ++ [ result ]
        ) [ idy ] colIndex;

      finalRow = if trivialDistance != null then null else fold' folder initialRow rowIndex;
    in
    if trivialDistance != null then trivialDistance else at finalRow pureLenB;

  levenshteinAtMost =
    let
      infixDifferAtMost1 = x: y: length x <= 1 && length y <= 1;
      infixDifferAtMost2 =
        x: y:
        let
          lenX = length x;
          lenY = length y;
          diff = lenX - lenY;
          infixX = slice 1 (lenX - 2) x;
          infixY = slice 1 (lenY - 2) y;
          delXR = slice 0 (lenX - 1) x;
          delXL = slice 1 (lenX - 1) x;
          delYR = slice 0 (lenY - 1) y;
          delYL = slice 1 (lenY - 1) y;
        in
        diff == 2 && infixX == y
        || diff == 1 && (infixX == delYR || infixX == delYL)
        || diff == 0 && (infixX == infixY || delXR == delYL || delXL == delYR);
    in
    k:
    if k <= 0 then
      a: b: a == b
    else
      a: b:
      let
        lenA = length a;
        lenB = length b;
        absDiff = max lenA lenB - min lenA lenB;
      in
      if absDiff > k then
        false
      else
        let
          prefix = commonPrefixLength a b;
          suffix = commonSuffixLength a b;
          merged = prefix + suffix;
          infixA = slice prefix (lenA - merged) a;
          infixB = slice prefix (lenB - merged) b;
        in
        k == 1 && infixDifferAtMost1 infixA infixB
        || k == 2 && infixDifferAtMost2 infixA infixB
        || k > 2 && levenshtein infixA infixB <= k;
}
