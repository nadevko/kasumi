final: prev:
let
  inherit (final.prelude) boolAs neq flip;
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
    imap0
    head
    tail
    ;
  inherit (final.attrs) mapValues pair fromPairs;
  inherit (final.types) isPath isStr typeOf;
  inherit (final.numeric) min max;
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
    asciiSet
    ascii
    subChar
    subchars
    charAt
    isPrintableAscii
    asciiUpper
    asciiLower
    toLower
    toUpper
    toStr
    escapeRegex
    split
    splitOnAny
    toSentenceCase
    optionalStr
    match
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
    sep: f: set:
    joinSep sep <| mapValues f set;

  # --- splits ----------------------------------------------------------------
  splitOnSep = sep: x: toStr x |> split (escapeRegex <| toStr sep) |> filter isStr;
  splitOnAny = seps: split "(${joinMapSep "|" escapeRegex seps})";

  # --- char operations -------------------------------------------------------
  subChar = "";
  charAt = x: i: slice i 1 x;
  chars = x: generate (charAt x) <| length x;
  subchars = x: chars x |> map (x: if x == subChar then null else x);
  charsMap = f: x: chars x |> joinMap f;

  # --- ascii -----------------------------------------------------------------
  ascii = subchars "\t\n\r !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
  asciiLower = chars "abcdefghijklmnopqrstuvwxyz";
  asciiUpper = chars "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  asciiSet = imap0 (flip pair) ascii |> filter (x: x.name != null) |> fromPairs;

  isPrintableAscii = i: 8 < i && i < 14 || 31 < i && i < 127;
  fromAscii = x: if asciiSet ? ${x} then asciiSet.${x} else null;
  toAscii = i: if isPrintableAscii i then at ascii i else null;

  toLower = replaceAll asciiUpper asciiLower;
  toUpper = replaceAll asciiLower asciiUpper;

  toSentenceCase =
    x:
    assert
      isStr x || throw "kasumi.strings.toSentenceCase: only strings are supported, but got ${typeOf x}.";
    toUpper (charAt x 0) + toLower (slice 1 (length x - 1) x);

  toCamelCase =
    x:
    assert
      isStr x || throw "kasumi.strings.toCamelCase: only strings are supported, but got ${typeOf x}.";
    let
      seps = [
        " "
        "-"
        "_"
      ];
      parts = toStr x |> splitOnAny seps |> filter (neq "");
      first = toLower <| head parts;
      rest = map toSentenceCase <| tail parts;
    in
    if parts == [ ] then "" else join <| [ first ] ++ rest;

  # --- rfc3986 ---------------------------------------------------------------
  unreserved = chars "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~";

  # --- generators ------------------------------------------------------------
  repeat = n: x: join <| replicate n x;
  replace = from: to: replaceAll [ from ] [ to ];

  removePrefix =
    seg: str:
    assert !isPath seg || throw "kasumi.strings.removePrefix: path as first argument aren't supported.";
    let
      len = length seg;
    in
    if slice 0 len str == seg then slice len (-1) str else str;

  removeSuffix =
    seg: str:
    assert !isPath seg || throw "kasumi.strings.removeSuffix: path as first argument aren't supported.";
    let
      len = length seg;
      segLen = length seg;
    in
    if segLen <= len && seg == slice (len - segLen) segLen str then slice 0 (len - segLen) str else str;

  trim =
    x:
    let
      str = match "[[:space:]]*(.*[^[:space:]])[[:space:]]*" x;
    in
    optionalStr (str != null) (head str);

  trimL =
    x:
    let
      str = match "[[:space:]]*(.*)" x;
    in
    optionalStr (str != null) (head str);

  trimR =
    x:
    let
      str = match "(.*[^[:space:]])[[:space:]]*" x;
    in
    optionalStr (str != null) (head str);

  # --- checks ----------------------------------------------------------------

  hasPrefix =
    seg: x:
    assert !isPath seg || throw "kasumi.strings.hasPrefix: path as first argument aren't supported.";
    slice 0 (length seg) x == seg;

  hasInfix =
    seg: x:
    assert !isPath x || throw "kasumi.strings.hasInfix: path as first argument aren't supported.";
    match ".*${escapeRegex seg}.*" "${x}" != null;

  hasSuffix =
    seg: x:
    assert !isPath seg || throw "kasumi.strings.hasSuffix: path as first argument aren't supported.";
    let
      len = length x;
      segLen = length seg;
    in
    len >= segLen && slice (len - segLen) segLen x == seg;

  # --- escapes ---------------------------------------------------------------

  # --- serialisation (bools) -------------------------------------------------
  optionalStr = cond: str: if cond then str else "";

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

  commonPrefixLength = commonSegmentLength (i: slice i 1);
  commonSuffixLength = commonSegmentLength (i: str: slice (length str - i - 1) 1 str);

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
